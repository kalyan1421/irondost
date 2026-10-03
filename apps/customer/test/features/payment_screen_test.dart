import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/payment/payment.dart';
import 'package:irondost_customer/features/payment/payment_repository.dart';
import 'package:irondost_customer/features/payment/payment_screen.dart';
import 'package:irondost_customer/features/payment/razorpay_checkout.dart';

import '../helpers.dart';

void main() {
  const paid = CheckoutPaid(paymentId: 'pay_1', orderId: 'order_o-1', signature: 'sig');

  Future<(GoRouter, FakeOrderRepository, FakePaymentRepository, FakeRazorpayCheckout)> pump(
    WidgetTester tester, {
    List<CheckoutResult> results = const [],
    Completer<void>? hold,
    OrderDto? order,
  }) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final placed = order ?? testOrder(method: PaymentMethod.online, pickupDate: istTodayForTest());
    final orders = FakeOrderRepository()..orders[placed.id] = placed;
    final payments = FakePaymentRepository(orders);
    final razorpay = FakeRazorpayCheckout(results)..hold = hold;
    final router = testRouter(
      {
        Routes.orderPay: () => const _Pay(),
        Routes.orderConfirmed: () => const Text('CONFIRMED PAGE'),
        Routes.home: () => const Text('HOME PAGE'),
        Routes.orders: () => const Text('ORDERS PAGE'),
      },
      initial: Routes.pay(placed.id),
      initialExtra: placed,
    );
    await tester.pumpWidget(
      themedRouter(
        router,
        overrides: [
          orderRepositoryProvider.overrideWithValue(orders),
          paymentRepositoryProvider.overrideWithValue(payments),
          razorpayCheckoutProvider.overrideWithValue(razorpay),
          paymentPollingProvider.overrideWithValue(instantPolling),
        ],
      ),
    );
    // While the window is held open the spinner never stops, so settling would wait forever.
    if (hold != null) {
      await tester.pump();
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
    return (router, orders, payments, razorpay);
  }

  testWidgets('while the Razorpay window is open it says so, and shows the order and amount', (tester) async {
    final hold = Completer<void>();
    final (_, _, _, razorpay) = await pump(tester, results: [paid], hold: hold);

    expect(razorpay.opened, hasLength(1));
    expect(find.text('Complete your payment'), findsOneWidget);
    expect(find.text('ID001046'), findsOneWidget);
    expect(find.text('₹248'), findsOneWidget);
    expect(find.text('Secure payment by Razorpay'), findsOneWidget);

    hold.complete();
    await tester.pumpAndSettle();
    expect(find.text('CONFIRMED PAGE'), findsOneWidget);
  });

  testWidgets('a verified payment ends on the confirmation', (tester) async {
    final (router, _, payments, _) = await pump(tester, results: [paid]);
    expect(payments.verified, hasLength(1));
    expect(router.state.matchedLocation, Routes.confirmed('o-1'));
  });

  testWidgets('cancelling shows the order is still booked, with Try again and cash instead', (tester) async {
    await pump(tester, results: [const CheckoutCancelled()]);

    expect(find.text('Payment cancelled'), findsOneWidget);
    expect(find.textContaining('Nothing was charged'), findsOneWidget);
    expect(find.textContaining('Your pickup is still booked for today, 4 – 8 PM. Order ID001046.'), findsOneWidget);
    expect(find.text('Try again · ₹248'), findsOneWidget);
    expect(find.text('Pay cash at delivery instead'), findsOneWidget);
  });

  testWidgets('Try again opens the payment again and a good payment finishes it', (tester) async {
    final (_, _, payments, razorpay) = await pump(tester, results: [const CheckoutFailed(code: 100, message: 'declined'), paid]);
    expect(find.text("Payment didn't go through"), findsOneWidget);

    await tester.tap(find.text('Try again · ₹248'));
    await tester.pumpAndSettle();

    expect(razorpay.opened, hasLength(2));
    expect(payments.verified, hasLength(1));
    expect(find.text('CONFIRMED PAGE'), findsOneWidget);
  });

  testWidgets('Pay cash at delivery instead switches the order and confirms it', (tester) async {
    final (_, orders, _, _) = await pump(tester, results: [const CheckoutCancelled()]);

    await tester.tap(find.text('Pay cash at delivery instead'));
    await tester.pumpAndSettle();

    expect(orders.switchedToCash, ['o-1']);
    expect(find.text('CONFIRMED PAGE'), findsOneWidget);
  });

  testWidgets('if cash cannot be set up it says so and stays', (tester) async {
    final (_, orders, _, _) = await pump(tester, results: [const CheckoutCancelled()]);
    orders.payOnDeliveryFailure = const ApiFailure(ApiFailureKind.offline);

    await tester.tap(find.text('Pay cash at delivery instead'));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't switch to cash on delivery"), findsOneWidget);
    expect(find.text('Payment cancelled'), findsOneWidget);
  });

  testWidgets('with online payment switched off there is no Try again, only cash', (tester) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final order = testOrder(method: PaymentMethod.online);
    final orders = FakeOrderRepository()..orders[order.id] = order;
    final payments = FakePaymentRepository(orders)..startFailures.add(const ApiFailure(ApiFailureKind.server, statusCode: 503, code: 'PAYMENTS_UNAVAILABLE'));
    final router = testRouter({Routes.orderPay: () => const _Pay(), Routes.home: () => const Text('HOME PAGE')}, initial: Routes.pay(order.id), initialExtra: order);
    await tester.pumpWidget(
      themedRouter(router, overrides: [
        orderRepositoryProvider.overrideWithValue(orders),
        paymentRepositoryProvider.overrideWithValue(payments),
        razorpayCheckoutProvider.overrideWithValue(FakeRazorpayCheckout()),
        paymentPollingProvider.overrideWithValue(instantPolling),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text("Online payment isn't available"), findsOneWidget);
    expect(find.textContaining('Try again'), findsNothing);
    expect(find.text('Pay cash at delivery instead'), findsOneWidget);
  });

  testWidgets('unconfirmed: the screen explains nobody needs to pay twice', (tester) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final order = testOrder(method: PaymentMethod.online);
    final orders = FakeOrderRepository()..orders[order.id] = order;
    final payments = FakePaymentRepository(orders)..verifyFailure = const ApiFailure(ApiFailureKind.offline);
    final router = testRouter({Routes.orderPay: () => const _Pay(), Routes.orderConfirmed: () => const Text('CONFIRMED PAGE'), Routes.orders: () => const Text('ORDERS PAGE')}, initial: Routes.pay(order.id), initialExtra: order);
    await tester.pumpWidget(
      themedRouter(router, overrides: [
        orderRepositoryProvider.overrideWithValue(orders),
        paymentRepositoryProvider.overrideWithValue(payments),
        razorpayCheckoutProvider.overrideWithValue(FakeRazorpayCheckout([paid])),
        paymentPollingProvider.overrideWithValue(instantPolling),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text("We're still confirming"), findsOneWidget);
    expect(find.textContaining("You don't need to pay again"), findsOneWidget);

    payments.markPaid(order.id);
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    expect(find.text('CONFIRMED PAGE'), findsOneWidget);
  });

  testWidgets('a cancelled order has nothing to pay', (tester) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final order = testOrder(method: PaymentMethod.online);
    final orders = FakeOrderRepository()..orders[order.id] = order;
    final payments = FakePaymentRepository(orders)..startFailures.add(const ApiFailure(ApiFailureKind.rejected, statusCode: 409, code: 'ORDER_CANCELLED'));
    final router = testRouter({Routes.orderPay: () => const _Pay(), Routes.home: () => const Text('HOME PAGE')}, initial: Routes.pay(order.id), initialExtra: order);
    await tester.pumpWidget(
      themedRouter(router, overrides: [
        orderRepositoryProvider.overrideWithValue(orders),
        paymentRepositoryProvider.overrideWithValue(payments),
        razorpayCheckoutProvider.overrideWithValue(FakeRazorpayCheckout()),
        paymentPollingProvider.overrideWithValue(instantPolling),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('This order was cancelled'), findsOneWidget);
    expect(find.text('Back to home'), findsOneWidget);
    expect(find.textContaining('Try again'), findsNothing);
    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();
    expect(find.text('HOME PAGE'), findsOneWidget);
  });
}

String istTodayForTest() => DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)).toIso8601String().substring(0, 10);

/// The payment route the way the app builds it: the order id from the path, the placed order from `extra`.
class _Pay extends StatelessWidget {
  const _Pay();

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    return PaymentScreen(orderId: state.pathParameters['id']!, initial: state.extra as OrderDto?);
  }
}
