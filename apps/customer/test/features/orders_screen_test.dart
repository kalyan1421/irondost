import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/auth/session.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/orders/orders_screen.dart';

import '../helpers.dart';

void main() {
  Future<(GoRouter, FakeOrderRepository)> pump(
    WidgetTester tester, {
    void Function(FakeOrderRepository repo)? seed,
  }) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = FakeOrderRepository();
    seed?.call(repo);
    final router = testRouter({
      Routes.orders: () => const OrdersScreen(),
      Routes.orderDetail: () => const Text('DETAIL PAGE'),
      Routes.home: () => const Text('HOME PAGE'),
    }, initial: Routes.orders);
    await tester.pumpWidget(
      themedRouter(
        router,
        overrides: [
          orderRepositoryProvider.overrideWithValue(repo),
          sessionProvider.overrideWith(SignedInSession.new),
        ],
      ),
    );
    await tester.pumpAndSettle();
    return (router, repo);
  }

  final today = istTodayForTest();
  OrderDto booked() => testOrder(
    id: 'a1',
    number: 'ID001046',
    method: PaymentMethod.online,
    paymentStatus: PaymentStatus.paid,
    paidPaise: 24800,
    pickupDate: today,
  );
  OrderDto ironing() => testOrder(
    id: 'a2',
    number: 'ID001042',
    status: OrderStatus.processing,
    totalPaise: 18000,
    pickedUpAt: DateTime.utc(2026, 10, 1, 12, 10),
    pieces: 12,
  );

  testWidgets(
    'Active shows each order with its status, windows and what is owed',
    (tester) async {
      await pump(tester, seed: (r) => r.listed.addAll([booked(), ironing()]));

      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Active (2)'), findsOneWidget);
      expect(find.text('ID001046'), findsOneWidget);
      expect(find.text('Booked'), findsOneWidget);
      expect(
        find.text('Today, 4 – 8 PM'),
        findsOneWidget,
        reason: 'the pickup window of the new order',
      );
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Track'), findsOneWidget);
      expect(
        find.text('Pay now'),
        findsOneWidget,
        reason: 'the second order has something due',
      );

      expect(find.text('ID001042'), findsOneWidget);
      expect(find.text('Being ironed'), findsOneWidget);
      expect(find.text('Picked up'), findsOneWidget);
      expect(find.text('Thu 1 Oct'), findsOneWidget);
      expect(find.text('₹180 due'), findsOneWidget);
      expect(find.text('₹180'), findsOneWidget);
    },
  );

  testWidgets('Pay now opens the payment choice for what is due', (
    tester,
  ) async {
    await pump(tester, seed: (r) => r.listed.add(ironing()));
    await tester.tap(find.text('Pay now'));
    await tester.pumpAndSettle();
    expect(find.text('Pay ₹180 for '), findsNothing);
    expect(
      find.textContaining('Pay ₹180 for', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Pay online now'), findsOneWidget);
    expect(find.text('Cash at delivery'), findsOneWidget);
  });

  testWidgets(
    'a cash order not yet picked up says it is paid at delivery, not that it is due',
    (tester) async {
      await pump(
        tester,
        seed: (r) => r.listed.add(
          testOrder(id: 'c1', number: 'ID001012', pickupDate: today),
        ),
      );
      expect(find.text('Pay at delivery'), findsOneWidget);
      expect(find.textContaining('due'), findsNothing);
    },
  );

  testWidgets('tapping an order opens it', (tester) async {
    final (router, _) = await pump(tester, seed: (r) => r.listed.add(booked()));
    await tester.tap(find.text('ID001046'));
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, Routes.order('a1'));
    expect(find.text('DETAIL PAGE'), findsOneWidget);
  });

  testWidgets(
    'Past lists delivered and cancelled orders with what happened to the money',
    (tester) async {
      await pump(
        tester,
        seed: (r) => r.listed.addAll([
          testOrder(
            id: 'd1',
            number: 'ID001038',
            status: OrderStatus.delivered,
            method: PaymentMethod.cod,
            paymentStatus: PaymentStatus.paid,
            paidPaise: 24800,
            deliveredAt: DateTime.utc(2026, 9, 26, 12),
          ),
          testOrder(
            id: 'x1',
            number: 'ID001035',
            status: OrderStatus.cancelled,
            cancelledAt: DateTime.utc(2026, 9, 23, 6),
          ),
          testOrder(
            id: 'd2',
            number: 'ID001031',
            status: OrderStatus.delivered,
            method: PaymentMethod.online,
            paymentStatus: PaymentStatus.paid,
            paidPaise: 24800,
            deliveredAt: DateTime.utc(2026, 9, 19, 12),
          ),
        ]),
      );
      expect(
        find.text('No active orders'),
        findsOneWidget,
        reason: 'nothing active',
      );

      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();

      expect(find.text('Delivered'), findsNWidgets(2));
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Cancelled before pickup · Wed 23 Sep'), findsOneWidget);
      expect(find.text('Nothing charged'), findsOneWidget);
      expect(find.text('Paid in cash'), findsOneWidget);
      expect(find.text('Paid online'), findsOneWidget);
      expect(find.text('Details'), findsNWidgets(3));
    },
  );

  testWidgets('a cancelled order that was paid says how much came back', (
    tester,
  ) async {
    await pump(
      tester,
      seed: (r) => r.listed.addAll([
        testOrder(
          id: 'x1',
          number: 'ID001035',
          status: OrderStatus.cancelled,
          method: PaymentMethod.online,
          paymentStatus: PaymentStatus.refunded,
          paidPaise: 24800,
          refundedPaise: 24800,
          cancelledAt: DateTime.utc(2026, 9, 23, 6),
        ),
        testOrder(
          id: 'x2',
          number: 'ID001036',
          status: OrderStatus.cancelled,
          method: PaymentMethod.online,
          paymentStatus: PaymentStatus.paid,
          paidPaise: 24800,
          cancelledAt: DateTime.utc(2026, 9, 24, 6),
        ),
      ]),
    );
    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();
    expect(find.text('₹248 refunded'), findsOneWidget);
    expect(find.text('Refund pending'), findsOneWidget);
  });

  testWidgets(
    'empty active orders explains how to start a pickup and opens Home',
    (tester) async {
      await pump(tester);
      expect(find.text('No active orders'), findsOneWidget);
      expect(
        find.text(
          'Your ongoing pickups appear here. Start a new pickup from Home.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Go to Home'));
      await tester.pumpAndSettle();
      expect(find.text('HOME PAGE'), findsOneWidget);
    },
  );

  testWidgets('no past orders is a quiet message, not a prompt to book', (
    tester,
  ) async {
    await pump(tester, seed: (r) => r.listed.add(booked()));
    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();
    expect(find.text('No past orders yet'), findsOneWidget);
    expect(find.text('Book a pickup'), findsNothing);
  });

  testWidgets(
    'when orders cannot be loaded it says so, and Try again recovers',
    (tester) async {
      final (_, repo) = await pump(
        tester,
        seed: (r) => r.listFailure = const ApiFailure(ApiFailureKind.offline),
      );
      expect(find.text("Couldn't load your orders"), findsOneWidget);
      expect(find.textContaining("You're offline"), findsOneWidget);

      repo
        ..listFailure = null
        ..listed.add(booked());
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('ID001046'), findsOneWidget);
    },
  );

  testWidgets('scrolling to the end of a long list loads the next page', (
    tester,
  ) async {
    final (_, repo) = await pump(
      tester,
      seed: (r) => r.listed.addAll([
        for (var i = 0; i < 25; i++)
          testOrder(id: 'a$i', number: 'ID${2000 + i}', pickupDate: today),
      ]),
    );
    expect(find.text('Active (25)'), findsOneWidget);
    expect(repo.listAsked, [(Scope.active, 1)]);

    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pumpAndSettle();
    expect(repo.listAsked, contains((Scope.active, 2)));
    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pumpAndSettle();
    expect(
      find.text('ID2024'),
      findsOneWidget,
      reason: 'the 25th order is there',
    );
  });
}

String istTodayForTest() => DateTime.now()
    .toUtc()
    .add(const Duration(hours: 5, minutes: 30))
    .toIso8601String()
    .substring(0, 10);
