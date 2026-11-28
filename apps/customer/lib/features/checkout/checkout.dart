import '../analytics/analytics.dart';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/uuid.dart';
import '../../data/api_client.dart';
import '../basket/basket.dart';
import '../orders/order_repository.dart';
import '../orders/orders_list.dart';
import '../schedule/schedule.dart';
import 'care_note.dart';

/// Why an order was not placed, in terms of what the customer should do next.
enum CheckoutProblem {
  /// The pickup or delivery window closed (or moved out of range) while the customer was deciding.
  slotClosed,

  /// The pickup window filled up while the customer was deciding: another time has to be picked.
  slotFull,

  /// The pickup address is outside the service area.
  notServiceable,

  /// Something in the basket was withdrawn. It has been taken out.
  itemsChanged,

  /// The code or the minimum order no longer holds: review the basket.
  basketChanged,

  /// The account is paused.
  paused,

  /// The customer signed in with Google and has not added a verified mobile number yet.
  phoneRequired,

  /// The API would not take the care note photos (one was already on another order, say). They were taken off the booking.
  photosRefused,

  /// No connection: nothing was charged, trying again is safe.
  offline,

  /// Anything else.
  failed,
}

/// The longest note the API accepts (`instructions` is capped at 500 characters).
const instructionsMaxLength = 500;

class CheckoutState {
  const CheckoutState({this.method = PaymentMethod.online, this.placing = false, this.problem, this.instructions = ''});

  final PaymentMethod method;
  final bool placing;
  final CheckoutProblem? problem;

  /// An optional note for the pickup, typed on the checkout screen.
  final String instructions;

  CheckoutState copyWith({PaymentMethod? method, bool? placing, CheckoutProblem? problem, bool clearProblem = false, String? instructions}) => CheckoutState(
        method: method ?? this.method,
        placing: placing ?? this.placing,
        problem: clearProblem ? null : (problem ?? this.problem),
        instructions: instructions ?? this.instructions,
      );
}

final checkoutProvider = NotifierProvider<CheckoutController, CheckoutState>(CheckoutController.new);

class CheckoutController extends Notifier<CheckoutState> {
  /// The request the current idempotency key belongs to. A retry of the same request reuses the key,
  /// so a timeout that hid a successful placement can never become a second order.
  String? _signature;
  String? _key;

  @override
  CheckoutState build() => const CheckoutState();

  void chooseMethod(PaymentMethod method) {
    if (state.placing) return;
    state = state.copyWith(method: method, clearProblem: true);
  }

  void dismissProblem() => state = state.copyWith(clearProblem: true);

  /// Keeps the note while the customer types. Editing it clears an old failure message, like
  /// changing the payment method does.
  void setInstructions(String text) {
    if (state.placing) return;
    state = state.copyWith(instructions: text, clearProblem: true);
  }

  /// Places the order. Returns it, or null with [CheckoutState.problem] set.
  ///
  /// Ignores a second call while one is running, so a double tap places one order.
  Future<OrderDto?> place({required Schedule schedule, required AddressDto address}) async {
    if (state.placing) return null;
    final basket = ref.read(basketProvider);
    if (basket.isEmpty || !schedule.isComplete) {
      state = state.copyWith(problem: CheckoutProblem.basketChanged);
      return null;
    }

    final note = state.instructions.trim();
    final care = ref.read(careNoteProvider);
    // A photo that is still on its way, or waiting to be retried, would be left off the order: the screen holds booking back.
    if (care.busy) return null;
    final careNote = care.note.trim();
    final dto = PlaceOrderDto(
      instructions: note.isEmpty ? null : note,
      careNote: careNote.isEmpty ? null : careNote,
      carePhotoUrls: care.photos.isEmpty ? null : [...care.photos],
      items: basket.items,
      promoCode: basket.promoCode,
      pickupDate: schedule.pickup!.date,
      pickupSlot: schedule.pickup!.slot,
      deliveryDate: schedule.delivery!.date,
      deliverySlot: schedule.delivery!.slot,
      pickupAddressId: address.id,
      paymentMethod: state.method,
    );
    final signature = jsonEncode(dto.toJson());
    if (signature != _signature) {
      _signature = signature;
      _key = newUuid();
    }

    state = state.copyWith(placing: true, clearProblem: true);
    try {
      final earlier = _ordersBefore();
      final order = await ref.read(orderRepositoryProvider).place(dto, idempotencyKey: _key!);
      _logPlaced(order, earlier);
      _placed();
      return order;
    } on ApiFailure catch (e) {
      final problem = _problemFor(e);
      if (e.code == 'IDEMPOTENCY_KEY_REUSED') _signature = null;
      state = state.copyWith(placing: false, problem: problem);
      return null;
    }
  }

  /// Orders the customer had before this one, as far as the loaded lists know. Null when they have not loaded.
  int? _ordersBefore() {
    final active = ref.read(ordersListProvider(Scope.active)).value;
    final past = ref.read(ordersListProvider(Scope.past)).value;
    if (active == null && past == null) return null;
    return (active?.total ?? 0) + (past?.total ?? 0);
  }

  void _logPlaced(OrderDto order, int? earlier) {
    final analytics = ref.read(analyticsProvider);
    final params = <String, Object>{
      'value': order.totalPaise / 100,
      'currency': 'INR',
      'payment_method': order.paymentMethod.json ?? '',
      'order_number': order.orderNumber,
    };
    analytics.log(Funnel.orderPlaced, params);
    if (earlier == 1) analytics.log(Funnel.secondOrder, params);
  }

  /// The order exists: start the next basket from scratch.
  void _placed() {
    ref.read(basketProvider.notifier).clear();
    ref.read(scheduleChoiceProvider.notifier).clear();
    ref.invalidate(ordersListProvider(Scope.active));
    ref.read(careNoteProvider.notifier).clear();
    _signature = null;
    _key = null;
    state = CheckoutState(method: state.method);
  }

  CheckoutProblem _problemFor(ApiFailure e) {
    switch (e.code) {
      case 'PICKUP_SLOT_CLOSED' || 'PICKUP_TOO_FAR_AHEAD' || 'DELIVERY_TOO_SOON' || 'DELIVERY_TOO_FAR_AHEAD' || 'INVALID_DATE':
        ref.invalidate(pickupSlotsProvider);
        return CheckoutProblem.slotClosed;
      case 'SLOT_FULL':
        // The windows on screen are out of date: the full one must show as Full when the customer goes back.
        ref.invalidate(pickupSlotsProvider);
        return CheckoutProblem.slotFull;
      case 'ADDRESS_NOT_SERVICEABLE':
        return CheckoutProblem.notServiceable;
      case 'ITEM_UNAVAILABLE':
        final gone = e.details?['catalogItemIds'];
        if (gone is List) {
          for (final id in gone) {
            ref.read(basketProvider.notifier).delete('$id');
          }
        }
        return CheckoutProblem.itemsChanged;
      case 'PROMO_INVALID' || 'BELOW_MIN_ORDER':
        return CheckoutProblem.basketChanged;
      case 'CUSTOMER_INACTIVE':
        return CheckoutProblem.paused;
      case 'PHONE_REQUIRED':
        return CheckoutProblem.phoneRequired;
      case 'INVALID_PHOTO' || 'TOO_MANY_PHOTOS':
        ref.read(careNoteProvider.notifier).photosRefused();
        return CheckoutProblem.photosRefused;
    }
    return e.isConnectivity ? CheckoutProblem.offline : CheckoutProblem.failed;
  }
}
