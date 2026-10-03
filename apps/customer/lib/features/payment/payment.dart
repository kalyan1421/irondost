import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';
import '../orders/order_repository.dart';
import '../orders/orders_list.dart';
import 'payment_repository.dart';
import 'razorpay_checkout.dart';

enum PaymentPhase {
  /// Asking the server for a Razorpay order.
  preparing,

  /// The Razorpay window is open.
  inCheckout,

  /// Razorpay said paid (or the customer went to a wallet app): waiting for the server to agree.
  confirming,

  /// The server has the payment.
  paid,

  /// Not paid. [PaymentState.failure] says why.
  failed,

  /// Razorpay said paid but the server has not confirmed yet. The webhook will settle it.
  unconfirmed,

  /// The customer chose to pay cash at delivery instead.
  cash,
}

enum PaymentFailure {
  /// The customer closed the payment window.
  cancelled,

  /// Declined by the bank or Razorpay.
  declined,

  /// No connection before anything was charged.
  offline,

  /// The server has no Razorpay keys (online payment is switched off).
  unavailable,

  /// The order was cancelled meanwhile.
  orderCancelled,

  /// The signature did not check out, or anything else.
  other,
}

class PaymentState {
  const PaymentState({this.phase = PaymentPhase.preparing, this.failure, this.message, this.order});

  final PaymentPhase phase;
  final PaymentFailure? failure;

  /// Razorpay's own description of a decline, when it gave one.
  final String? message;

  /// The order as the server last reported it (after paying or switching to cash).
  final OrderDto? order;

  bool get busy => phase == PaymentPhase.preparing || phase == PaymentPhase.inCheckout || phase == PaymentPhase.confirming;
}

/// How long to wait for the server to confirm a payment Razorpay says was made.
class PaymentPolling {
  const PaymentPolling({this.attempts = 8, this.every = const Duration(seconds: 3)});
  final int attempts;
  final Duration every;
}

final paymentPollingProvider = Provider<PaymentPolling>((ref) => const PaymentPolling());

/// Paying one order online, start to finish. The screen calls [start]; everything after that is state.
///
/// Kept alive (not auto-disposed) so a payment that finishes while the customer is in a wallet app
/// still has somewhere to report to; [PaymentController.start] begins from scratch each time.
final paymentProvider = NotifierProvider.family<PaymentController, PaymentState, String>(PaymentController.new);

class PaymentController extends Notifier<PaymentState> {
  PaymentController(this.orderId);
  final String orderId;

  PaymentRepository get _payments => ref.read(paymentRepositoryProvider);
  OrderRepository get _orders => ref.read(orderRepositoryProvider);

  @override
  PaymentState build() => const PaymentState();

  /// Opens the payment. Does nothing while one is already under way.
  Future<void> start() async {
    if (_starting) return;
    _starting = true;
    try {
      await _run();
    } finally {
      _starting = false;
    }
  }

  bool _starting = false;

  Future<void> _run() async {
    state = const PaymentState();

    final CheckoutParamsDto params;
    try {
      params = await _payments.start(orderId);
    } on ApiFailure catch (e) {
      switch (e.code) {
        case 'NOTHING_DUE':
          // Paid already (an earlier attempt landed): show the order as it is.
          await _settle(attempts: 1);
          return;
        case 'ORDER_CANCELLED':
          state = const PaymentState(phase: PaymentPhase.failed, failure: PaymentFailure.orderCancelled);
        case 'PAYMENTS_UNAVAILABLE':
          state = const PaymentState(phase: PaymentPhase.failed, failure: PaymentFailure.unavailable);
        default:
          state = PaymentState(phase: PaymentPhase.failed, failure: e.isConnectivity ? PaymentFailure.offline : PaymentFailure.other);
      }
      return;
    }

    state = const PaymentState(phase: PaymentPhase.inCheckout);
    final result = await ref.read(razorpayCheckoutProvider).open(params);
    switch (result) {
      case CheckoutPaid():
        await _verify(result);
      case CheckoutCancelled():
        state = const PaymentState(phase: PaymentPhase.failed, failure: PaymentFailure.cancelled);
      case CheckoutFailed(:final message):
        state = PaymentState(phase: PaymentPhase.failed, failure: PaymentFailure.declined, message: message);
      case CheckoutExternalWallet():
        // The wallet app finishes the payment; the server hears about it from Razorpay.
        await _settle();
    }
  }

  Future<void> _verify(CheckoutPaid paid) async {
    state = const PaymentState(phase: PaymentPhase.confirming);
    try {
      await _payments.verify(razorpayOrderId: paid.orderId, razorpayPaymentId: paid.paymentId, razorpaySignature: paid.signature);
    } on ApiFailure catch (e) {
      if (e.code == 'INVALID_SIGNATURE') {
        state = const PaymentState(phase: PaymentPhase.failed, failure: PaymentFailure.other);
        return;
      }
      // No answer (offline, timeout, 5xx): the money may have moved, so ask again instead of failing.
      await _settle();
      return;
    }
    await _settle(attempts: 1);
  }

  /// Asks the server until it reports the order paid, for [attempts] tries.
  Future<void> _settle({int? attempts}) async {
    state = const PaymentState(phase: PaymentPhase.confirming);
    final polling = ref.read(paymentPollingProvider);
    final tries = attempts ?? polling.attempts;
    for (var i = 0; i < tries; i++) {
      if (i > 0) await Future<void>.delayed(polling.every);
      try {
        final order = await _orders.get(orderId);
        if (order.paymentStatus == PaymentStatus.paid || order.amountDuePaise <= 0) {
          _paid(order);
          return;
        }
      } on ApiFailure {
        // Try again after the pause.
      }
    }
    state = const PaymentState(phase: PaymentPhase.unconfirmed);
  }

  void _paid(OrderDto order) {
    ref.invalidate(orderProvider(orderId));
    ref.invalidate(ordersListProvider(Scope.active));
    state = PaymentState(phase: PaymentPhase.paid, order: order);
  }

  /// "Check again" on the unconfirmed screen.
  Future<void> checkAgain() async {
    if (state.phase != PaymentPhase.unconfirmed) return;
    await _settle();
  }

  /// "Pay cash at delivery instead". Returns whether it worked.
  Future<bool> payCash() async {
    if (state.busy) return false;
    final before = state;
    state = const PaymentState(phase: PaymentPhase.preparing);
    try {
      final order = await _orders.payOnDelivery(orderId);
      ref.invalidate(orderProvider(orderId));
      ref.invalidate(ordersListProvider(Scope.active));
      state = PaymentState(phase: PaymentPhase.cash, order: order);
      return true;
    } on ApiFailure catch (e) {
      // Paid in the meantime, or cancelled: show the truth rather than the old failure.
      if (e.code == 'ALREADY_PAID') {
        await _settle(attempts: 1);
      } else {
        state = PaymentState(phase: before.phase, failure: before.failure, message: before.message);
      }
      return false;
    }
  }
}
