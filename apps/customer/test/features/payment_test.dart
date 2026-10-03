import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/payment/payment.dart';
import 'package:irondost_customer/features/payment/payment_repository.dart';
import 'package:irondost_customer/features/payment/razorpay_checkout.dart';

import '../helpers.dart';

void main() {
  const orderId = 'o-1';
  late FakeOrderRepository orders;
  late FakePaymentRepository payments;
  late FakeRazorpayCheckout razorpay;
  late ProviderContainer container;

  void setUp({List<CheckoutResult> results = const []}) {
    orders = FakeOrderRepository()..orders[orderId] = testOrder(id: orderId, method: PaymentMethod.online);
    payments = FakePaymentRepository(orders);
    razorpay = FakeRazorpayCheckout(results);
    container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(orders),
        paymentRepositoryProvider.overrideWithValue(payments),
        razorpayCheckoutProvider.overrideWithValue(razorpay),
        paymentPollingProvider.overrideWithValue(instantPolling),
      ],
    );
    addTearDown(container.dispose);
  }

  PaymentController pay() => container.read(paymentProvider(orderId).notifier);
  PaymentState state() => container.read(paymentProvider(orderId));

  const paid = CheckoutPaid(paymentId: 'pay_1', orderId: 'order_o-1', signature: 'sig');

  test('opens Razorpay with what the server prepared, then has the server verify what came back', () async {
    setUp(results: [paid]);
    await pay().start();

    expect(payments.started, [orderId]);
    expect(razorpay.opened.single.razorpayOrderId, 'order_o-1');
    expect(razorpay.opened.single.amountPaise, 24800);
    expect(payments.verified.single, (orderId: 'order_o-1', paymentId: 'pay_1', signature: 'sig'));
    expect(state().phase, PaymentPhase.paid);
    expect(state().order!.paymentStatus, PaymentStatus.paid);
  });

  test('goes through preparing, the Razorpay window and confirming, in that order', () async {
    setUp(results: [paid]);
    final seen = <PaymentPhase>[];
    container.listen(paymentProvider(orderId), (_, next) => seen.add(next.phase), fireImmediately: true);

    await pay().start();
    expect(seen.toSet().toList(), [PaymentPhase.preparing, PaymentPhase.inCheckout, PaymentPhase.confirming, PaymentPhase.paid]);
  });

  test('a second start while one is running does nothing', () async {
    setUp(results: [paid]);
    razorpay.hold = Completer<void>();
    final first = pay().start();
    await Future<void>.delayed(Duration.zero);
    await pay().start();
    expect(payments.started, hasLength(1));
    razorpay.hold!.complete();
    await first;
    expect(state().phase, PaymentPhase.paid);
  });

  group('when it does not work', () {
    test('closing the window is a cancellation, not an error', () async {
      setUp(results: [const CheckoutCancelled()]);
      await pay().start();
      expect(state().phase, PaymentPhase.failed);
      expect(state().failure, PaymentFailure.cancelled);
      expect(payments.verified, isEmpty);
    });

    test('a decline keeps what Razorpay said', () async {
      setUp(results: [const CheckoutFailed(code: 100, message: 'Payment failed: bank declined')]);
      await pay().start();
      expect(state().failure, PaymentFailure.declined);
      expect(state().message, 'Payment failed: bank declined');
    });

    test('trying again starts a fresh payment', () async {
      setUp(results: [const CheckoutCancelled(), paid]);
      await pay().start();
      expect(state().phase, PaymentPhase.failed);
      await pay().start();
      expect(payments.started, hasLength(2));
      expect(state().phase, PaymentPhase.paid);
    });

    test('no connection before the window opens', () async {
      setUp();
      payments.startFailures.add(const ApiFailure(ApiFailureKind.offline));
      await pay().start();
      expect(state().failure, PaymentFailure.offline);
      expect(razorpay.opened, isEmpty);
    });

    test('online payment switched off on the server', () async {
      setUp();
      payments.startFailures.add(const ApiFailure(ApiFailureKind.server, statusCode: 503, code: 'PAYMENTS_UNAVAILABLE'));
      await pay().start();
      expect(state().failure, PaymentFailure.unavailable);
    });

    test('a cancelled order cannot be paid', () async {
      setUp();
      payments.startFailures.add(const ApiFailure(ApiFailureKind.rejected, statusCode: 409, code: 'ORDER_CANCELLED'));
      await pay().start();
      expect(state().failure, PaymentFailure.orderCancelled);
    });

    test('an order already paid shows as paid instead of opening Razorpay', () async {
      setUp();
      payments.markPaid(orderId);
      payments.startFailures.add(const ApiFailure(ApiFailureKind.rejected, statusCode: 409, code: 'NOTHING_DUE'));
      await pay().start();
      expect(state().phase, PaymentPhase.paid);
      expect(razorpay.opened, isEmpty);
    });

    test('a signature the server rejects is a failure, and is not treated as paid', () async {
      setUp(results: [paid]);
      payments.verifyFailure = const ApiFailure(ApiFailureKind.rejected, statusCode: 400, code: 'INVALID_SIGNATURE');
      await pay().start();
      expect(state().phase, PaymentPhase.failed);
      expect(state().failure, PaymentFailure.other);
    });
  });

  group('money may have moved but the server has not said so', () {
    test('verify gets no answer: it asks about the order until the webhook has marked it paid', () async {
      setUp(results: [paid]);
      payments.verifyFailure = const ApiFailure(ApiFailureKind.timeout);
      var asked = 0;
      orders.getHook = () {
        asked++;
        if (asked == 2) payments.markPaid(orderId); // the webhook lands between the tries
      };
      await pay().start();
      expect(asked, 2);
      expect(state().phase, PaymentPhase.paid);
    });

    test('still unpaid after the tries: says it is confirming, and Check again can finish it', () async {
      setUp(results: [paid]);
      payments.verifyFailure = const ApiFailure(ApiFailureKind.offline);
      await pay().start();
      expect(state().phase, PaymentPhase.unconfirmed);

      payments.markPaid(orderId);
      await pay().checkAgain();
      expect(state().phase, PaymentPhase.paid);
    });

    test('a wallet app finishes elsewhere: the order is polled', () async {
      setUp(results: [const CheckoutExternalWallet('paytm')]);
      orders.getHook = () => payments.markPaid(orderId);
      await pay().start();
      expect(state().phase, PaymentPhase.paid);
      expect(payments.verified, isEmpty, reason: 'there is nothing to verify on the device');
    });
  });

  group('paying cash at delivery instead', () {
    test('switches the order and ends on the confirmation', () async {
      setUp(results: [const CheckoutFailed(code: 100)]);
      await pay().start();
      expect(await pay().payCash(), isTrue);
      expect(orders.switchedToCash, [orderId]);
      expect(state().phase, PaymentPhase.cash);
      expect(state().order!.paymentMethod, PaymentMethod.cod);
    });

    test('if the server refuses, the failure screen stays', () async {
      setUp(results: [const CheckoutCancelled()]);
      await pay().start();
      orders.payOnDeliveryFailure = const ApiFailure(ApiFailureKind.offline);
      expect(await pay().payCash(), isFalse);
      expect(state().phase, PaymentPhase.failed);
      expect(state().failure, PaymentFailure.cancelled);
    });

    test('if it was paid in the meantime, the order shows as paid', () async {
      setUp(results: [const CheckoutCancelled()]);
      await pay().start();
      payments.markPaid(orderId);
      orders.payOnDeliveryFailure = const ApiFailure(ApiFailureKind.rejected, statusCode: 409, code: 'ALREADY_PAID');
      expect(await pay().payCash(), isFalse);
      expect(state().phase, PaymentPhase.paid);
    });
  });
}
