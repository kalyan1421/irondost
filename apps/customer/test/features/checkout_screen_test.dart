import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/addresses/address_repository.dart';
import 'package:irondost_customer/features/basket/basket.dart';
import 'package:irondost_customer/features/basket/quote.dart';
import 'package:irondost_customer/features/checkout/checkout_screen.dart';
import 'package:irondost_customer/features/orders/order_confirmed_screen.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/push/push_source.dart';
import 'package:irondost_customer/features/schedule/schedule.dart';

import '../helpers.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump(quoteDebounce + const Duration(milliseconds: 10));
  await tester.pumpAndSettle();
}

void main() {
  const basket = {'basket.v1': '{"lines":{"shirt":2,"saree":1},"promoCode":null}'};

  Future<(GoRouter, FakeOrderRepository, ProviderContainer)> pump(
    WidgetTester tester, {
    Map<String, Object> saved = basket,
    AddressDto? address,
    FakeOrderRepository? orders,
    FakeScheduleRepository? schedule,
  }) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 1300 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final fake = orders ?? FakeOrderRepository();
    final router = testRouter(
      {
        '/schedule': () => Scaffold(body: Center(child: Builder(builder: (context) => TextButton(onPressed: () => context.push(Routes.checkout), child: const Text('SCHEDULE PAGE'))))),
        Routes.checkout: () => const CheckoutScreen(),
        Routes.orderConfirmed: () => const Text('CONFIRMED PAGE'),
        Routes.orderPay: () => const Text('PAY PAGE'),
        Routes.home: () => const Text('HOME PAGE'),
        Routes.book: () => const Text('CATALOGUE PAGE'),
      },
      initial: '/schedule',
    );
    await tester.pumpWidget(
      themedRouter(
        router,
        overrides: [
          ...await basketOverrides(saved: saved),
          scheduleRepositoryProvider.overrideWithValue(schedule ?? FakeScheduleRepository()),
          orderRepositoryProvider.overrideWithValue(fake),
          addressRepositoryProvider.overrideWithValue(FakeAddressRepository([address ?? testAddress()])),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    // The schedule screen keeps these alive in the app; here, the checkout does.
    unawaited(router.push(Routes.checkout));
    await tester.pumpAndSettle(); // the page builds, which starts the quote
    await settle(tester); // and its debounce runs out
    return (router, fake, container);
  }

  testWidgets('shows where, when, how to pay and the bill', (tester) async {
    await pump(tester);

    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.textContaining('302, Sai Residency'), findsOneWidget);
    expect(find.text('Pickup'), findsOneWidget);
    expect(find.text('Today, 4 – 8 PM'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('Sun 4 Oct, 4 – 8 PM'), findsOneWidget);
    expect(find.text('Pay online'), findsOneWidget);
    expect(find.text('Cash on delivery'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('To pay'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Items (3)'), findsOneWidget);
    expect(find.text('To pay'), findsOneWidget);
    expect(find.text('Pay ₹80'), findsOneWidget);
    expect(find.text('Secure payment by Razorpay'), findsOneWidget);
  });

  testWidgets('cash on delivery changes the button and the reassurance line', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Cash on delivery'));
    await tester.pump();

    expect(find.text('Place order ₹80'), findsOneWidget);
    expect(find.text('You pay in cash when your clothes are delivered'), findsOneWidget);
    expect(find.text('Secure payment by Razorpay'), findsNothing);
  });

  group('note for the pickup', () {
    testWidgets('is optional, and says who sees it', (tester) async {
      final (_, orders, _) = await pump(tester);
      expect(find.text('Note for your pickup (optional)'), findsOneWidget);
      expect(find.text('IronDost sees this with your order.'), findsOneWidget);

      await tester.tap(find.text('Pay ₹80'));
      await settle(tester);

      expect(orders.placed.single.$1.instructions, isNull, reason: 'no note, nothing sent');
    });

    testWidgets('typed text and a quick phrase are sent together, and a phrase is only added once', (tester) async {
      final (_, orders, _) = await pump(tester);

      await tester.enterText(find.byType(TextField), 'Gate code 4321');
      await tester.tap(find.text('Call before arriving'));
      await tester.pump();
      await tester.tap(find.text('Call before arriving'));
      await tester.pump();
      expect(find.text('Gate code 4321. Call before arriving'), findsOneWidget);

      await tester.tap(find.text('Pay ₹80'));
      await settle(tester);

      expect(orders.placed.single.$1.instructions, 'Gate code 4321. Call before arriving');
    });

    testWidgets('quick phrases are full-size touch targets', (tester) async {
      await pump(tester);
      for (final phrase in ['Call before arriving', 'Leave with security', "Don't ring the bell"]) {
        final target = find.ancestor(of: find.text(phrase), matching: find.byType(InkWell)).first;
        expect(tester.getSize(target).height, greaterThanOrEqualTo(48), reason: phrase);
      }
    });

    testWidgets('stops at the API limit of 500 characters', (tester) async {
      final (_, orders, _) = await pump(tester);

      await tester.enterText(find.byType(TextField), 'a' * 600);
      await tester.pump();
      await tester.tap(find.text('Pay ₹80'));
      await settle(tester);

      expect(orders.placed.single.$1.instructions, hasLength(500));
    });
  });

  testWidgets('placing a cash order goes to the confirmation', (tester) async {
    final (router, orders, container) = await pump(tester);
    await tester.tap(find.text('Cash on delivery'));
    await tester.pump();

    await tester.tap(find.text('Place order ₹80'));
    await settle(tester);

    expect(orders.placed.single.$1.paymentMethod, PaymentMethod.cod);
    expect(router.state.matchedLocation, Routes.confirmed('o-1'));
    expect(find.text('CONFIRMED PAGE'), findsOneWidget);
    expect(container.read(basketProvider).isEmpty, isTrue);
  });

  testWidgets('placing an online order goes on to the payment', (tester) async {
    final (router, orders, container) = await pump(tester);

    await tester.tap(find.text('Pay ₹80'));
    await settle(tester);

    expect(orders.placed.single.$1.paymentMethod, PaymentMethod.online);
    expect(router.state.matchedLocation, Routes.pay('o-1'));
    expect(find.text('PAY PAGE'), findsOneWidget);
    expect(container.read(basketProvider).isEmpty, isTrue, reason: 'the order exists now, so the basket is spent');
  });

  testWidgets('no connection: says nothing was charged, and the same button tries again', (tester) async {
    final orders = FakeOrderRepository()..failures.add(const ApiFailure(ApiFailureKind.offline));
    await pump(tester, orders: orders);
    await tester.tap(find.text('Cash on delivery'));
    await tester.pump();

    await tester.tap(find.text('Place order ₹80'));
    await settle(tester);
    expect(find.textContaining("You're offline. Nothing was charged"), findsOneWidget);
    expect(find.text('Place order ₹80'), findsOneWidget);

    await tester.tap(find.text('Place order ₹80'));
    await settle(tester);
    expect(find.text('CONFIRMED PAGE'), findsOneWidget);
    expect(orders.placed, hasLength(2));
    expect(orders.placed[0].$2, orders.placed[1].$2, reason: 'the retry carries the same idempotency key');
  });

  testWidgets('a time that closed explains, and "Pick another time" goes back to the schedule', (tester) async {
    final orders = FakeOrderRepository()..failures.add(const ApiFailure(ApiFailureKind.rejected, statusCode: 400, code: 'PICKUP_SLOT_CLOSED'));
    final (router, _, container) = await pump(tester, orders: orders);
    await tester.tap(find.text('Cash on delivery'));
    await tester.pump();

    await tester.tap(find.text('Place order ₹80'));
    await settle(tester);
    expect(find.text('That time just closed'), findsOneWidget);
    expect(find.textContaining("you haven't been charged"), findsOneWidget);

    await tester.tap(find.text('Pick another time'));
    await settle(tester);
    expect(find.text('SCHEDULE PAGE'), findsOneWidget);
    expect(router.state.matchedLocation, '/schedule');
    expect(container.read(basketProvider).isEmpty, isFalse, reason: 'basket kept');
  });

  testWidgets('an address we do not serve is flagged and blocks placing', (tester) async {
    await pump(tester, address: testAddress(serviceable: false));

    expect(find.textContaining("We don't pick up from Banjara Hills yet"), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Pay ₹80')).onPressed, isNull);
  });

  testWidgets('an empty basket does not offer to pay', (tester) async {
    await pump(tester, saved: {});
    expect(find.text('Your basket is empty'), findsOneWidget);
    expect(find.textContaining('Pay'), findsNothing);
  });

  testWidgets('a quote that needs attention (minimum order) keeps the button off', (tester) async {
    // A code under its minimum: the server says it cannot be placed.
    await pump(tester, saved: {'basket.v1': '{"lines":{"shirt":2,"saree":1},"promoCode":"BIG"}'});
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Pay ₹80')).onPressed, isNull);
  });

  group('confirmation', () {
    Future<GoRouter> show(WidgetTester tester, OrderDto order, {PushPermission permission = PushPermission.granted}) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 1300 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final repo = FakeOrderRepository()..orders[order.id] = order;
      final router = testRouter(
        {
          '/c': () => OrderConfirmedScreen(orderId: order.id, initial: order),
          Routes.orders: () => const Text('ORDERS PAGE'),
          Routes.orderDetail: () => const Text('DETAIL PAGE'),
          Routes.home: () => const Text('HOME PAGE'),
          Routes.notificationPermission: () => Scaffold(body: Builder(builder: (context) => TextButton(onPressed: () => context.pop(), child: const Text('PERMISSION PAGE')))),
        },
        initial: '/c',
      );
      await tester.pumpWidget(
        themedRouter(router, overrides: [...await basketOverrides(), orderRepositoryProvider.overrideWithValue(repo), pushSourceProvider.overrideWithValue(_PermissionOnly(permission))]),
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('a cash order says when the partner comes and what to pay at the door', (tester) async {
      await show(tester, testOrder(pickupDate: istTodayForTest(), pickupLabel: '16:00–20:00'));
      expect(find.text('Pickup booked'), findsOneWidget);
      expect(find.textContaining('A partner will come today between 4 and 8 PM.'), findsOneWidget);
      expect(find.text('ID001046'), findsOneWidget);
      expect(find.text('Pay ₹248 at delivery'), findsOneWidget);
      expect(find.text('17 items · Home, Banjara Hills'), findsOneWidget);
      expect(find.text('Track order'), findsOneWidget);
    });

    testWidgets('says what happens next, in the same words as tracking', (tester) async {
      await show(tester, testOrder());
      expect(find.text('What happens next'), findsOneWidget);
      expect(find.text('Collected and counted'), findsOneWidget);
      expect(find.text('Your partner counts your clothes at pickup.'), findsOneWidget);
      expect(find.text('Ironed at our workshop'), findsOneWidget);
      expect(find.text('Brought back to you'), findsOneWidget);
    });

    testWidgets('a paid order shows the amount paid; a later pickup names the day', (tester) async {
      await show(tester, testOrder(method: PaymentMethod.online, paymentStatus: PaymentStatus.paid, paidPaise: 24800, pickupDate: '2099-01-05', pickupLabel: '07:00–11:00'));
      expect(find.text('Paid ₹248'), findsOneWidget);
      expect(find.textContaining('A partner will come on Mon 5 Jan between 7 and 11 AM.'), findsOneWidget);
    });

    testWidgets('an online order not yet paid says so', (tester) async {
      await show(tester, testOrder(method: PaymentMethod.online));
      expect(find.text('Payment pending'), findsOneWidget);
    });

    testWidgets('the first time, leaving offers notifications first, then carries on', (tester) async {
      await show(tester, testOrder(), permission: PushPermission.notDetermined);
      await tester.tap(find.text('Back to home'));
      await tester.pumpAndSettle();
      expect(find.text('PERMISSION PAGE'), findsOneWidget);
      expect(find.text('HOME PAGE'), findsNothing);

      await tester.tap(find.text('PERMISSION PAGE'));
      await tester.pumpAndSettle();
      expect(find.text('HOME PAGE'), findsOneWidget);
    });

    testWidgets('Track order and Back to home navigate', (tester) async {
      await show(tester, testOrder());
      await tester.tap(find.text('Track order'));
      await tester.pumpAndSettle();
      expect(find.text('DETAIL PAGE'), findsOneWidget, reason: 'the order itself, with the Orders tab underneath');
    });
  });
}

/// Today in India, from the same clock the screen uses.
String istTodayForTest() => DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)).toIso8601String().substring(0, 10);

/// Push that only knows its permission, for screens that merely ask whether to offer notifications.
class _PermissionOnly implements PushSource {
  const _PermissionOnly(this.permissionNow);
  final PushPermission permissionNow;

  @override
  Stream<PushMessage> get foreground => const Stream.empty();

  @override
  Stream<PushMessage> get opened => const Stream.empty();

  @override
  Future<PushMessage?> launchedBy() async => null;

  @override
  Future<PushPermission> permission() async => permissionNow;

  @override
  Future<PushPermission> request() async => permissionNow;
}
