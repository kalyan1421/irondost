import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:irondost_customer/app/provider_retry.dart';
import 'package:irondost_customer/design/theme.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/addresses/address_repository.dart';
import 'package:irondost_customer/features/addresses/location_service.dart';
import 'package:irondost_customer/features/addresses/place.dart';
import 'package:irondost_customer/features/auth/auth_repository.dart';
import 'package:irondost_customer/features/auth/session.dart';
import 'package:irondost_customer/features/basket/basket.dart';
import 'package:irondost_customer/features/basket/quote.dart';
import 'package:irondost_customer/features/catalogue/catalogue.dart';
import 'package:irondost_customer/features/offers/promotions.dart';
import 'package:irondost_customer/features/notifications/notifications.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/payment/payment.dart';
import 'package:irondost_customer/features/payment/payment_repository.dart';
import 'package:irondost_customer/features/payment/razorpay_checkout.dart';
import 'package:irondost_customer/features/schedule/schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps [child] in the IronDost theme (no font downloads) and a ProviderScope.
Widget themed(Widget child, {List<Override> overrides = const [], Brightness brightness = Brightness.light}) => ProviderScope(
      retry: noAutomaticRetry,
      overrides: overrides,
      child: MaterialApp(theme: buildTheme(brightness, font: plainFont), home: child),
    );

/// Like [themed] but with a real router, for screens that navigate. Each of [pages] is a path shown as plain text
/// (its path), so a test can see where it ended up. [home] is the route the test starts on.
GoRouter testRouter(Map<String, Widget Function()> screens, {required String initial, Object? initialExtra}) => GoRouter(
      initialLocation: initial,
      initialExtra: initialExtra,
      routes: [for (final e in screens.entries) GoRoute(path: e.key, builder: (_, _) => e.value())],
    );

Widget themedRouter(GoRouter router, {List<Override> overrides = const [], Brightness brightness = Brightness.light}) => ProviderScope(
      retry: noAutomaticRetry,
      overrides: overrides,
      child: MaterialApp.router(theme: buildTheme(brightness, font: plainFont), routerConfig: router),
    );

/// An [AuthRepository] whose answers the test controls.
class FakeAuth implements AuthRepository {
  bool signedIn = false;
  AuthFailure? sendFailure;
  AuthFailure? confirmFailure;
  final sentTo = <String>[];

  @override
  Future<bool> hasCredentials() async => signedIn;

  @override
  Future<String?> token({bool forceRefresh = false}) async => signedIn ? 'test-token' : null;

  @override
  Future<PhoneChallenge> sendCode(String phone, {PhoneChallenge? resendOf, void Function()? onAutoVerified}) async {
    sentTo.add(phone);
    if (sendFailure != null) throw sendFailure!;
    return PhoneChallenge(phone: phone, verificationId: 'v-${sentTo.length}');
  }

  @override
  Future<void> confirmCode(PhoneChallenge challenge, String code) async {
    if (confirmFailure != null) throw confirmFailure!;
    signedIn = true;
  }

  @override
  Future<void> signOut() async => signedIn = false;
}

// ── Addresses ──────────────────────────────────────────────────────────────

AddressDto testAddress({
  String id = 'a1',
  String label = 'Home',
  bool isPrimary = true,
  bool serviceable = true,
  String street = 'Road No. 12',
  String area = 'Banjara Hills',
}) =>
    AddressDto(
      id: id,
      label: label,
      houseNo: '302',
      building: 'Sai Residency',
      street: street,
      area: area,
      landmark: null,
      city: 'Hyderabad',
      state: 'Telangana',
      pincode: '500034',
      latitude: 17.4126,
      longitude: 78.4482,
      isPrimary: isPrimary,
      formatted: '302, Sai Residency, $street, $area, Hyderabad 500034',
      serviceable: serviceable,
      notServiceableReason: serviceable ? null : NotServiceableReason.outsideRadius,
    );

/// An [AddressRepository] that keeps addresses in memory and answers the area check as told.
class FakeAddressRepository implements AddressRepository {
  FakeAddressRepository([List<AddressDto>? initial]) : addresses = [...?initial];

  final List<AddressDto> addresses;
  final created = <CreateAddressDto>[];
  final updated = <String, UpdateAddressDto>{};
  final removed = <String>[];
  bool areaServiceable = true;
  bool areaFails = false;
  final checked = <Place>[];

  @override
  Future<List<AddressDto>> list() async => [...addresses];

  @override
  Future<AddressDto> create(CreateAddressDto dto) async {
    created.add(dto);
    final saved = testAddress(id: 'new-${created.length}', label: dto.label, isPrimary: dto.isPrimary, street: dto.street, area: dto.area ?? '');
    addresses.add(saved);
    return saved;
  }

  @override
  Future<AddressDto> update(String id, UpdateAddressDto dto) async {
    updated[id] = dto;
    return addresses.firstWhere((a) => a.id == id);
  }

  @override
  Future<void> remove(String id) async {
    removed.add(id);
    addresses.removeWhere((a) => a.id == id);
  }

  @override
  Future<ServiceAreaCheckDto> checkArea(Place place) async {
    checked.add(place);
    if (areaFails) throw const ApiFailure(ApiFailureKind.offline);
    return ServiceAreaCheckDto(
      serviceable: areaServiceable,
      reason: areaServiceable ? null : NotServiceableReason.outsideRadius,
      distanceKm: areaServiceable ? 4.8 : 15.9,
    );
  }
}

/// A [LocationService] whose answers the test controls.
class FakeLocation implements LocationService {
  LocationAccess access = LocationAccess.granted;
  Place? here = const Place(latitude: 17.4126, longitude: 78.4482, street: 'Road No. 12', area: 'Banjara Hills', city: 'Hyderabad', state: 'Telangana', pincode: '500034');
  final reversed = <(double, double)>[];
  List<Place> searchResults = const [];
  Completer<Place?>? holdReverse;

  @override
  Future<LocationAccess> requestAccess() async => access;

  @override
  Future<Place?> currentPlace() async => here;

  @override
  Future<Place?> reverse(double latitude, double longitude) async {
    reversed.add((latitude, longitude));
    if (holdReverse != null) return holdReverse!.future;
    return Place(latitude: latitude, longitude: longitude, street: 'Street at $latitude', city: 'Hyderabad', state: 'Telangana', pincode: '500034');
  }

  @override
  Future<List<Place>> search(String query) async => searchResults;

  @override
  Future<void> openSettings(LocationAccess access) async {}
}

/// A signed-in session, so providers that need one (addresses) work without the API.
class SignedInSession extends SessionController {
  @override
  Future<Session> build() async => const SignedIn(Profile(id: 'u1', phone: '+919876543210', name: 'Priya Sharma', isComplete: true));
}

// ── Catalogue and basket ───────────────────────────────────────────────────

CatalogItemDto testItem(String id, String name, int paise, {String categoryId = 'ironing', num sortOrder = 0, bool isActive = true, int? offerPaise, ItemUnit unit = ItemUnit.piece}) =>
    CatalogItemDto(
      id: id,
      categoryId: categoryId,
      name: name,
      description: null,
      unit: unit,
      pricePaise: paise,
      offerPricePaise: offerPaise,
      effectivePricePaise: offerPaise ?? paise,
      imageUrl: null,
      sortOrder: sortOrder,
      isActive: isActive,
    );

CatalogCategoryDto testCategory(String id, String name, List<CatalogItemDto> items, {num sortOrder = 0, bool isActive = true}) =>
    CatalogCategoryDto(id: id, name: name, slug: id, imageUrl: null, sortOrder: sortOrder, isActive: isActive, items: items);

/// Ironing (shirt, trousers, saree) and Wash & iron (shirt), priced like the seed data.
List<CatalogCategoryDto> testCatalog() => [
      testCategory('ironing', 'Ironing', [
        testItem('shirt', 'Shirt / T-shirt', 1500),
        testItem('trousers', 'Trousers / Jeans', 1500, sortOrder: 1),
        testItem('saree', 'Saree', 5000, sortOrder: 2),
      ]),
      testCategory('wash-and-iron', 'Wash & iron', [
        testItem('wash-shirt', 'Shirt / T-shirt', 3500, categoryId: 'wash-and-iron'),
      ], sortOrder: 1),
    ];

/// Overrides for anything that touches the basket: saved basket in preferences, a price list, a signed-in customer.
/// [load], when given, replaces the price list fetch (to fail it, say). [quotes] answers basket quotes.
Future<List<Override>> basketOverrides({
  Map<String, Object> saved = const {},
  List<CatalogCategoryDto>? catalog,
  Future<List<CatalogCategoryDto>> Function()? load,
  QuoteRepository? quotes,
  List<PromotionDto> promotions = const [],
}) async {
  SharedPreferences.setMockInitialValues(saved);
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    catalogProvider.overrideWith((ref) => load != null ? load() : Future.value(catalog ?? testCatalog())),
    sessionProvider.overrideWith(SignedInSession.new),
    quoteRepositoryProvider.overrideWithValue(quotes ?? FakeQuoteRepository()),
    promotionsProvider.overrideWith((ref) async => promotions),
  ];
}

/// Prices baskets from [testCatalog] the way the API does: promo codes, a minimum order and a delivery fee.
///
/// Codes: `WELCOME20` 20% off (min ₹100), `EXPIRED`, `USEDUP`, `BIG` (min ₹500). Anything else is not found.
class FakeQuoteRepository implements QuoteRepository {
  final calls = <(List<OrderLineInput>, String?)>[];
  int minOrderPaise = 0;
  int deliveryFeePaise = 0;
  ApiFailure? failure;

  @override
  Future<QuoteDto> quote(List<OrderLineInput> items, String? promoCode) async {
    calls.add((items, promoCode));
    if (failure != null) throw failure!;
    final prices = {for (final c in testCatalog()) for (final i in c.items) i.id: i};
    final lines = [
      for (final line in items)
        QuoteLineDto(
          catalogItemId: line.catalogItemId,
          name: prices[line.catalogItemId]!.name,
          unit: ItemUnit.piece,
          unitPricePaise: prices[line.catalogItemId]!.effectivePricePaise,
          quantity: line.quantity,
          lineTotalPaise: prices[line.catalogItemId]!.effectivePricePaise * line.quantity,
        ),
    ];
    final subtotal = lines.fold<int>(0, (a, l) => a + l.lineTotalPaise.toInt());

    QuoteDtoPromoError? error;
    num? promoShortfall;
    var discount = 0;
    String? applied;
    if (promoCode != null) {
      final min = switch (promoCode) {
        'WELCOME20' => 10000,
        'BIG' => 50000,
        _ => 0,
      };
      if (promoCode == 'EXPIRED') {
        error = QuoteDtoPromoError.promoExpired;
      } else if (promoCode == 'USEDUP') {
        error = QuoteDtoPromoError.promoLimitReached;
      } else if (promoCode != 'WELCOME20' && promoCode != 'BIG') {
        error = QuoteDtoPromoError.promoNotFound;
      } else if (subtotal < min) {
        error = QuoteDtoPromoError.promoMinOrder;
        promoShortfall = min - subtotal;
      } else {
        applied = promoCode;
        discount = promoCode == 'WELCOME20' ? subtotal ~/ 5 : subtotal ~/ 10;
      }
    }
    final shortfall = subtotal < minOrderPaise ? minOrderPaise - subtotal : null;
    return QuoteDto(
      lines: lines,
      subtotalPaise: subtotal,
      discountPaise: discount,
      deliveryFeePaise: deliveryFeePaise,
      totalPaise: subtotal - discount + deliveryFeePaise,
      promoCode: applied,
      promoError: error,
      promoShortfallPaise: promoShortfall,
      minOrderShortfallPaise: shortfall,
      canPlaceOrder: shortfall == null && (promoCode == null || error == null),
    );
  }
}

PromotionDto testPromo(String code, String title, {int minOrderPaise = 0, int? maxDiscountPaise}) => PromotionDto(
      id: 'p-$code',
      code: code,
      title: title,
      description: null,
      discountType: DiscountType.percent,
      discountValue: 20,
      minOrderPaise: minOrderPaise,
      maxDiscountPaise: maxDiscountPaise,
      perCustomerLimit: null,
      validFrom: DateTime(2026, 1, 1),
      validTo: DateTime(2026, 12, 31),
      imageUrl: null,
      isActive: true,
    );

// ── Schedule ───────────────────────────────────────────────────────────────

/// One window, with its IST hours turned into the UTC instants the API sends.
SlotOptionDto testSlot(String date, TimeSlot slot, {bool available = true}) {
  final (startHour, endHour, label) = switch (slot) {
    TimeSlot.morning => (7, 11, '07:00–11:00'),
    TimeSlot.noon => (11, 16, '11:00–16:00'),
    _ => (16, 20, '16:00–20:00'),
  };
  DateTime at(int hour) {
    final d = DateTime.parse(date);
    return DateTime.utc(d.year, d.month, d.day, hour).subtract(const Duration(hours: 5, minutes: 30));
  }

  return SlotOptionDto(date: date, slot: slot, label: label, startsAt: at(startHour), endsAt: at(endHour), available: available);
}

/// Saturday 3 Oct 2026, 6:30 pm in India: this morning's and noon's windows are over.
const testToday = '2026-10-03';
const testDays = ['2026-10-03', '2026-10-04', '2026-10-05', '2026-10-06', '2026-10-07'];

/// Pickup windows for [testDays]; the API's rules for delivery (20 hours after the pickup ends).
class FakeScheduleRepository implements ScheduleRepository {
  FakeScheduleRepository({Set<SlotKey>? closed, bool todayOver = true})
      : closed = closed ??
            {
              if (todayOver) (date: testToday, slot: TimeSlot.morning),
              if (todayOver) (date: testToday, slot: TimeSlot.noon),
            };

  /// Pickup windows that are not open.
  final Set<SlotKey> closed;
  ApiFailure? pickupFailure;
  ApiFailure? deliveryFailure;
  final deliveryAsked = <SlotKey>[];
  int pickupAsked = 0;

  static const _order = [TimeSlot.morning, TimeSlot.noon, TimeSlot.evening];

  @override
  Future<List<SlotOptionDto>> pickupSlots() async {
    pickupAsked++;
    if (pickupFailure != null) throw pickupFailure!;
    return [
      for (final d in testDays)
        for (final s in _order) testSlot(d, s, available: !closed.contains((date: d, slot: s))),
    ];
  }

  @override
  Future<List<SlotOptionDto>> deliverySlots(String pickupDate, TimeSlot pickupSlot) async {
    deliveryAsked.add((date: pickupDate, slot: pickupSlot));
    if (deliveryFailure != null) throw deliveryFailure!;
    final earliest = testSlot(pickupDate, pickupSlot).endsAt.add(const Duration(hours: 20));
    return [
      for (final d in testDays.where((d) => d.compareTo(pickupDate) >= 0))
        for (final s in _order) testSlot(d, s, available: !testSlot(d, s).startsAt.isBefore(earliest)),
    ];
  }
}

// ── Orders ─────────────────────────────────────────────────────────────────

OrderDto testOrder({
  OrderStatus status = OrderStatus.pending,
  DateTime? pickedUpAt,
  DateTime? deliveredAt,
  DateTime? cancelledAt,
  int refundedPaise = 0,
  PersonRefDto? pickupDriver,
  PersonRefDto? deliveryDriver,
  DateTime? dispatchFailedAt,
  List<OrderEventDto>? events,
  String id = 'o-1',
  String number = 'ID001046',
  PaymentMethod method = PaymentMethod.cod,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
  int totalPaise = 24800,
  int paidPaise = 0,
  String pickupDate = testToday,
  String pickupLabel = '16:00–20:00',
  String deliveryDate = '2026-10-04',
  String deliveryLabel = '16:00–20:00',
  int pieces = 17,
}) =>
    OrderDto(
      id: id,
      orderNumber: number,
      status: status,
      source: OrderSource.customerApp,
      instructions: null,
      pickupDate: pickupDate,
      pickupSlot: TimeSlot.evening,
      pickupSlotLabel: pickupLabel,
      deliveryDate: deliveryDate,
      deliverySlot: TimeSlot.evening,
      deliverySlotLabel: deliveryLabel,
      pickupAddress: _orderAddress,
      deliveryAddress: _orderAddress,
      items: [
        OrderItemDto(id: 'i1', catalogItemId: 'shirt', name: 'Shirt / T-shirt', unit: ItemUnit.piece, unitPricePaise: 1500, quantity: pieces, lineTotalPaise: 1500 * pieces),
      ],
      subtotalPaise: totalPaise,
      discountPaise: 0,
      deliveryFeePaise: 0,
      totalPaise: totalPaise,
      paidPaise: paidPaise,
      refundedPaise: refundedPaise,
      amountDuePaise: totalPaise - paidPaise,
      promoCode: null,
      paymentMethod: method,
      paymentStatus: paymentStatus,
      customer: null,
      pickupDriver: pickupDriver,
      deliveryDriver: deliveryDriver,
      allowedNextStatuses: const [],
      dispatchFailedAt: dispatchFailedAt,
      cancelReason: null,
      pickedUpAt: pickedUpAt,
      deliveredAt: deliveredAt,
      cancelledAt: cancelledAt,
      events: events,
      createdAt: DateTime.utc(2026, 10, 3, 12),
      updatedAt: DateTime.utc(2026, 10, 3, 12),
    );

const _orderAddress = OrderAddressDto(
  label: 'Home',
  formatted: '302, Sai Residency, Road No. 12, Banjara Hills, Hyderabad 500034',
  houseNo: '302',
  building: 'Sai Residency',
  street: 'Road No. 12',
  area: 'Banjara Hills',
  landmark: null,
  city: 'Hyderabad',
  state: 'Telangana',
  pincode: '500034',
  latitude: 17.4126,
  longitude: 78.4482,
  contactName: 'Priya Sharma',
  contactPhone: '+919876543210',
);

/// An [OrderRepository] that "places" orders from the request, remembering what it was sent.
/// Failures queued in [failures] are thrown one per call.
class FakeOrderRepository implements OrderRepository {
  final placed = <(PlaceOrderDto, String)>[];
  final failures = <ApiFailure>[];
  final orders = <String, OrderDto>{};
  Completer<void>? hold;

  @override
  Future<OrderDto> place(PlaceOrderDto dto, {required String idempotencyKey}) async {
    placed.add((dto, idempotencyKey));
    if (hold != null) await hold!.future;
    if (failures.isNotEmpty) throw failures.removeAt(0);
    // Same key, same order: what the API's idempotency does.
    final prior = placed.indexWhere((p) => p.$2 == idempotencyKey);
    final order = testOrder(
      id: 'o-${prior + 1}',
      method: dto.paymentMethod,
      pickupDate: dto.pickupDate,
      deliveryDate: dto.deliveryDate,
      pieces: dto.items.fold(0, (a, i) => a + i.quantity.toInt()),
    );
    orders[order.id] = order;
    return order;
  }

  /// Runs on every [get], before it answers: a way for a test to change the world between tries.
  void Function()? getHook;

  int getCount = 0;

  @override
  Future<OrderDto> get(String id) async {
    getCount++;
    getHook?.call();
    if (getFailure != null) throw getFailure!;
    return orders[id] ?? testOrder(id: id);
  }

  /// Thrown by [get] while set.
  ApiFailure? getFailure;

  /// The customer's orders, newest first, as [list] serves them.
  final listed = <OrderDto>[];
  final listAsked = <(Scope, int)>[];
  ApiFailure? listFailure;

  @override
  Future<OrderPageDto> list(Scope scope, {int page = 1, int pageSize = 20}) async {
    listAsked.add((scope, page));
    if (listFailure != null) throw listFailure!;
    bool finished(OrderDto o) => o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled;
    final pool = [for (final o in listed) if (scope == Scope.past ? finished(o) : !finished(o)) o];
    return OrderPageDto(items: pool.skip((page - 1) * pageSize).take(pageSize).toList(), page: page, pageSize: pageSize, total: pool.length);
  }
  final cancelled = <(String, String?)>[];
  ApiFailure? cancelFailure;

  @override
  Future<OrderDto> cancel(String id, {String? reason}) async {
    if (cancelFailure != null) throw cancelFailure!;
    cancelled.add((id, reason));
    final before = orders[id] ?? testOrder(id: id);
    final order = testOrder(
      id: id,
      status: OrderStatus.cancelled,
      method: before.paymentMethod,
      paymentStatus: before.paymentStatus,
      paidPaise: before.paidPaise.toInt(),
      cancelledAt: DateTime.utc(2026, 10, 3, 9),
    );
    orders[id] = order;
    return order;
  }

  final switchedToCash = <String>[];
  ApiFailure? payOnDeliveryFailure;

  @override
  Future<OrderDto> payOnDelivery(String id) async {
    if (payOnDeliveryFailure != null) throw payOnDeliveryFailure!;
    switchedToCash.add(id);
    final order = testOrder(id: id, method: PaymentMethod.cod);
    orders[id] = order;
    return order;
  }
}

// ── Payments ───────────────────────────────────────────────────────────────

/// The API's Razorpay endpoints. A verified payment marks the order paid in [orders], as the server would.
class FakePaymentRepository implements PaymentRepository {
  FakePaymentRepository(this.orders);

  final FakeOrderRepository orders;
  final started = <String>[];
  final verified = <({String orderId, String paymentId, String signature})>[];
  final startFailures = <ApiFailure>[];
  ApiFailure? verifyFailure;

  @override
  Future<CheckoutParamsDto> start(String orderId) async {
    started.add(orderId);
    if (startFailures.isNotEmpty) throw startFailures.removeAt(0);
    final order = orders.orders[orderId] ?? testOrder(id: orderId, method: PaymentMethod.online);
    return CheckoutParamsDto(
      keyId: 'rzp_test_key',
      razorpayOrderId: 'order_$orderId',
      amountPaise: order.amountDuePaise,
      currency: CheckoutParamsDtoCurrency.inr,
      orderNumber: order.orderNumber,
      prefill: const CheckoutPrefillDto(name: 'Priya Sharma', contact: '+919876543210', email: null),
    );
  }

  @override
  Future<PaymentStatusDto> verify({required String razorpayOrderId, required String razorpayPaymentId, required String razorpaySignature}) async {
    verified.add((orderId: razorpayOrderId, paymentId: razorpayPaymentId, signature: razorpaySignature));
    if (verifyFailure != null) throw verifyFailure!;
    markPaid(razorpayOrderId.replaceFirst('order_', ''));
    return const PaymentStatusDto(paymentStatus: 'PAID');
  }

  /// What the server (or its webhook) does once a payment is captured.
  void markPaid(String orderId) {
    final order = orders.orders[orderId] ?? testOrder(id: orderId, method: PaymentMethod.online);
    orders.orders[orderId] = testOrder(
      id: orderId,
      method: order.paymentMethod,
      paymentStatus: PaymentStatus.paid,
      paidPaise: order.totalPaise.toInt(),
      totalPaise: order.totalPaise.toInt(),
    );
  }
}

/// Razorpay Checkout, answering from a script: one result per opening.
class FakeRazorpayCheckout implements RazorpayCheckout {
  FakeRazorpayCheckout([List<CheckoutResult>? results]) : results = [...?results];

  final List<CheckoutResult> results;
  final opened = <CheckoutParamsDto>[];
  Completer<void>? hold;

  @override
  Future<CheckoutResult> open(CheckoutParamsDto params) async {
    opened.add(params);
    if (hold != null) await hold!.future;
    return results.isEmpty ? const CheckoutCancelled() : results.removeAt(0);
  }
}

/// Polls instantly, so "wait for the webhook" tests run without waiting.
const instantPolling = PaymentPolling(attempts: 3, every: Duration.zero);

// ── Notifications ──────────────────────────────────────────────────────────

NotificationDto testNotification(String id, {String type = 'order_status', String title = 'Partner on the way', String body = 'Ravi is coming to collect order ID001046.', Object? data = const {'orderId': 'o-1', 'status': 'PICKUP_ASSIGNED'}, DateTime? readAt, DateTime? createdAt}) =>
    NotificationDto(id: id, type: type, title: title, body: body, data: data, readAt: readAt, createdAt: createdAt ?? DateTime.now().toUtc());

/// The inbox, newest first. [unread] is computed from what is in [inbox].
class FakeNotificationRepository implements NotificationRepository {
  final inbox = <NotificationDto>[];
  final listAsked = <int>[];
  final markedRead = <String>[];
  int markedAll = 0;
  ApiFailure? listFailure;
  ApiFailure? markFailure;

  @override
  Future<NotificationPageDto> list({int page = 1, int pageSize = 20}) async {
    listAsked.add(page);
    if (listFailure != null) throw listFailure!;
    return NotificationPageDto(
      items: inbox.skip((page - 1) * pageSize).take(pageSize).toList(),
      unread: inbox.where((n) => n.readAt == null).length,
      page: page,
      pageSize: pageSize,
      total: inbox.length,
    );
  }

  @override
  Future<void> markRead(String id) async {
    if (markFailure != null) throw markFailure!;
    markedRead.add(id);
  }

  @override
  Future<void> markAllRead() async {
    if (markFailure != null) throw markFailure!;
    markedAll++;
  }
}
