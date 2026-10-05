import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/design/theme.dart';
import 'package:irondost_customer/features/basket/basket.dart';
import 'package:irondost_customer/features/orders/order_bill_screen.dart';
import 'package:irondost_customer/features/orders/order_detail_screen.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';

import '../helpers.dart';

void main() {
  final today = istTodayForTest();
  const ravi = PersonRefDto(id: 'd1', name: 'Ravi K.', phone: '+919876500001');
  final pickedUp = DateTime.utc(2026, 10, 1, 12, 10);

  Future<(GoRouter, FakeOrderRepository, ProviderContainer)> pump(
    WidgetTester tester,
    OrderDto order, {
    OrderDto? fresh,
    bool seedInitial = true,
    Map<String, Object> basket = const {},
    ApiFailure? getFailure,
  }) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 1000 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = FakeOrderRepository()
      ..orders[order.id] = fresh ?? order
      ..getFailure = getFailure;
    final router = testRouter(
      {
        Routes.orders: () => const Text('ORDERS PAGE'),
        Routes.orderDetail: () => const _Detail(),
        Routes.orderBill: () => const _Bill(),
        Routes.basket: () => const Text('BASKET PAGE'),
        Routes.orderPay: () => const Text('PAY PAGE'),
        Routes.book: () => const Text('CATALOGUE PAGE'),
      },
      initial: Routes.order(order.id),
      initialExtra: seedInitial ? order : null,
    );
    await tester.pumpWidget(
      themedRouter(
        router,
        overrides: [
          orderRepositoryProvider.overrideWithValue(repo),
          ...await basketOverrides(saved: basket),
        ],
      ),
    );
    await tester.pumpAndSettle();
    return (
      router,
      repo,
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first)),
    );
  }

  testWidgets(
    'a new order: step 1, when the pickup is, the timeline and that a partner will appear',
    (tester) async {
      await pump(
        tester,
        testOrder(
          method: PaymentMethod.online,
          paymentStatus: PaymentStatus.paid,
          paidPaise: 24800,
          pickupDate: today,
        ),
      );

      expect(find.text('Order ID001046'), findsOneWidget);
      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Booked'), findsWidgets);
      expect(find.text('Pickup today, 4\u00A0\u2060–\u2060\u00A08\u00A0PM'), findsOneWidget);
      expect(find.text('Finding a partner near you'), findsOneWidget);
      expect(find.text('Ironing'), findsOneWidget);
      expect(
        find.text(
          "You'll see your partner's name and number here once they accept.",
        ),
        findsOneWidget,
      );
      expect(find.text('17 items · ₹248'), findsOneWidget);
      expect(find.text('Paid online'), findsOneWidget);
      expect(find.text('Book again'), findsNothing);
    },
  );

  testWidgets(
    'a pickup that found no partner says it is running late, and offers a call',
    (tester) async {
      await pump(
        tester,
        testOrder(
          pickupDate: today,
          dispatchFailedAt: DateTime.utc(2026, 10, 3, 9, 30),
        ),
      );

      expect(find.text('Pickup running late'), findsOneWidget);
      expect(find.text('Window today, 4\u00A0\u2060–\u2060\u00A08\u00A0PM'), findsOneWidget);
      expect(
        find.textContaining("will call you if we can't make it by 8 PM"),
        findsOneWidget,
      );
      expect(find.text('Call us'), findsOneWidget);
      expect(
        find.textContaining("You'll see your partner's name"),
        findsNothing,
      );
    },
  );

  testWidgets(
    'being ironed: who picked up, how to reach them, and what is owed',
    (tester) async {
      await pump(
        tester,
        testOrder(
          status: OrderStatus.processing,
          totalPaise: 18000,
          pieces: 12,
          pickedUpAt: pickedUp,
        ).withPickupDriver(ravi),
      );

      expect(find.text('Being ironed'), findsWidgets);
      expect(find.text('Step 3 of 5'), findsOneWidget);
      expect(find.textContaining('Delivery estimate missed:'), findsOneWidget);
      expect(find.text('Ravi K.'), findsOneWidget);
      expect(find.text('Picked up your clothes'), findsOneWidget);
      expect(find.byTooltip('Call Ravi'), findsOneWidget);
      expect(
        find.text('₹180 is due. Pay the partner in cash or pay online now.'),
        findsOneWidget,
      );
      expect(
        find.text('Thu 1 Oct, 5:40 PM · 12 items counted'),
        findsOneWidget,
      );
    },
  );

  testWidgets('out for delivery names the partner for the cash at the door', (
    tester,
  ) async {
    await pump(
      tester,
      testOrder(
        status: OrderStatus.outForDelivery,
        totalPaise: 18000,
        deliveryDate: today,
        pickedUpAt: pickedUp,
        deliveryDriver: ravi,
      ),
    );
    expect(find.text('Out for delivery'), findsWidgets);
    expect(find.text('Arriving today, 4\u00A0\u2060–\u2060\u00A08\u00A0PM'), findsOneWidget);
    expect(find.text('Bringing your clothes back'), findsOneWidget);
    expect(
      find.text(
        '₹180 is due. Pay Ravi in cash at the door, or pay online now.',
      ),
      findsOneWidget,
    );
  });

  group('the status hero and the partner card', () {
    /// Fill colour of each of the five progress segments, left to right.
    List<Color?> bar(WidgetTester tester) => [
      for (final w in tester.widgetList<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.constraints?.minHeight == 4 &&
              w.constraints?.maxHeight == 4,
        ),
      ))
        (w.decoration! as BoxDecoration).color,
    ];

    IdColors colors(WidgetTester tester) =>
        tester.element(find.byType(Scaffold).first).colors;

    Finder callButtons() => find.byWidgetPredicate(
      (w) => w is IconButton && (w.tooltip ?? '').startsWith('Call '),
    );

    testWidgets('the bar fills to the current step, in the primary colour while on time', (
      tester,
    ) async {
      await pump(
        tester,
        testOrder(
          status: OrderStatus.processing,
          deliveryDate: '2099-10-06',
          pickedUpAt: pickedUp,
          pickupDriver: ravi,
        ),
      );
      final c = colors(tester);

      expect(bar(tester), [c.primary, c.primary, c.primary, c.border, c.border]);
      expect(find.text('Step 3 of 5'), findsOneWidget, reason: 'the words stay');
      expect(find.text('Call us'), findsNothing, reason: 'nothing is late');
    });

    testWidgets('a missed delivery estimate turns the bar amber and offers a call', (
      tester,
    ) async {
      await pump(
        tester,
        testOrder(
          status: OrderStatus.processing,
          pickedUpAt: pickedUp,
        ).withPickupDriver(ravi),
      );
      final c = colors(tester);

      expect(bar(tester), [c.warning, c.warning, c.warning, c.border, c.border]);
      expect(find.textContaining('Delivery estimate missed:'), findsOneWidget);
      expect(find.text('Call us'), findsOneWidget);
    });

    testWidgets('a late pickup has an amber bar and still exactly one Call us', (
      tester,
    ) async {
      await pump(
        tester,
        testOrder(
          pickupDate: today,
          dispatchFailedAt: DateTime.utc(2026, 10, 3, 9, 30),
        ),
      );
      final c = colors(tester);

      expect(bar(tester), [c.warning, c.border, c.border, c.border, c.border]);
      expect(find.text('Call us'), findsOneWidget, reason: 'the notice has it; the hero adds none');
    });

    testWidgets('before anyone accepts, the card has the same shape and no call button', (
      tester,
    ) async {
      await pump(tester, testOrder(pickupDate: today));

      expect(find.text('Your partner'), findsOneWidget);
      expect(
        find.text(
          "You'll see your partner's name and number here once they accept.",
        ),
        findsOneWidget,
      );
      expect(find.text('Pickup partner'), findsNothing);
      expect(callButtons(), findsNothing);
    });

    testWidgets('once assigned, the card names the role and offers a call', (
      tester,
    ) async {
      await pump(
        tester,
        testOrder(
          status: OrderStatus.processing,
          deliveryDate: '2099-10-06',
          pickedUpAt: pickedUp,
          pickupDriver: ravi,
        ),
      );

      expect(find.text('Pickup partner'), findsOneWidget);
      expect(find.text('Ravi K.'), findsOneWidget);
      expect(find.text('Your partner'), findsNothing);
      expect(callButtons(), findsOneWidget);
    });

    testWidgets('on the way back, it is the delivery partner', (tester) async {
      await pump(
        tester,
        testOrder(
          status: OrderStatus.outForDelivery,
          deliveryDate: '2099-10-06',
          pickedUpAt: pickedUp,
          deliveryDriver: ravi,
        ),
      );

      expect(find.text('Delivery partner'), findsOneWidget);
      expect(find.text('Pickup partner'), findsNothing);
    });
  });

  testWidgets(
    'an online order that was never paid says so, whatever its stage',
    (tester) async {
      await pump(
        tester,
        testOrder(method: PaymentMethod.online, pickupDate: today),
      );
      expect(
        find.text(
          "₹248 isn't paid yet. Pay online now, or switch to cash on delivery.",
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'delivered: who and when, the summary, and a way to book the same again',
    (tester) async {
      await pump(
        tester,
        testOrder(
          status: OrderStatus.delivered,
          method: PaymentMethod.cod,
          paymentStatus: PaymentStatus.paid,
          paidPaise: 18000,
          totalPaise: 18000,
          pieces: 12,
          pickedUpAt: pickedUp,
          deliveredAt: DateTime.utc(2026, 10, 3, 12, 2),
          deliveryDriver: ravi,
        ),
      );

      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Sat 3 Oct, 5:32 PM · by Ravi K.'), findsOneWidget);
      expect(find.text('Thu 1 Oct, 5:40 PM'), findsOneWidget);
      expect(find.text('12, ironed'), findsOneWidget);
      expect(find.text('₹180 in cash'), findsOneWidget);
      expect(find.text('Items and bill'), findsOneWidget);
      expect(find.text('Something wrong with an item?'), findsOneWidget);
      expect(find.text('Book the same again'), findsOneWidget);
      expect(find.text('Step 5 of 5'), findsNothing);
    },
  );

  testWidgets('cancelled: says who and why, and where the refund is', (
    tester,
  ) async {
    await pump(
      tester,
      testOrder(
        status: OrderStatus.cancelled,
        method: PaymentMethod.online,
        paymentStatus: PaymentStatus.paid,
        paidPaise: 24800,
        cancelledAt: DateTime.utc(2026, 10, 2, 8, 44),
      ).withCancelReason('I booked by mistake'),
    );

    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('You cancelled this order'), findsOneWidget);
    expect(
      find.text('Fri 2 Oct, 2:14 PM · "I booked by mistake"'),
      findsOneWidget,
    );
    expect(
      find.textContaining('₹248 is awaiting refund confirmation'),
      findsOneWidget,
    );
    expect(find.text('₹248 · refund pending'), findsOneWidget);
    expect(find.text('Book again'), findsOneWidget);
  });

  testWidgets('what the API says now replaces what the list showed', (
    tester,
  ) async {
    final listed = testOrder(pickupDate: today);
    await pump(
      tester,
      listed,
      fresh: testOrder(
        status: OrderStatus.processing,
        pickedUpAt: pickedUp,
        pickupDate: today,
      ),
    );
    expect(find.text('Being ironed'), findsWidgets);
    expect(find.text('Step 3 of 5'), findsOneWidget);
  });

  testWidgets(
    'an order the list did not carry loads, and a failure to load can be retried',
    (tester) async {
      final order = testOrder(pickupDate: today);
      final (_, repo, _) = await pump(
        tester,
        order,
        seedInitial: false,
        getFailure: const ApiFailure(ApiFailureKind.offline),
      );
      expect(find.text("Couldn't load this order"), findsOneWidget);

      repo.getFailure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Order ID001046'), findsOneWidget);
      expect(find.text('Step 1 of 5'), findsOneWidget);
    },
  );

  group('cancelling', () {
    final booked = testOrder(pickupDate: today);

    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this order?'), findsOneWidget);
    }

    Finder inSheet(String text) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(text),
    );

    testWidgets(
      'before pickup the order can be cancelled, with a reason, and the screen shows it cancelled',
      (tester) async {
        final (_, repo, _) = await pump(tester, booked);
        expect(
          find.text('Free to cancel until your clothes are picked up.'),
          findsOneWidget,
        );

        await openSheet(tester);
        expect(
          find.text("Nothing has been charged, so there's nothing to refund."),
          findsOneWidget,
        );
        await tester.tap(find.text('I booked by mistake'));
        await tester.pump();
        await tester.tap(inSheet('Cancel order'));
        await tester.pumpAndSettle();

        expect(repo.cancelled, [('o-1', 'I booked by mistake')]);
        expect(find.text('Cancel this order?'), findsNothing);
        expect(find.text('Order ID001046 cancelled'), findsOneWidget);
        expect(find.text('You cancelled this order'), findsOneWidget);
        expect(find.text('Book again'), findsOneWidget);
      },
    );

    testWidgets('a reason is optional, and tapping it again clears it', (
      tester,
    ) async {
      final (_, repo, _) = await pump(tester, booked);
      await openSheet(tester);
      await tester.tap(find.text("I won't be at home"));
      await tester.pump();
      await tester.tap(find.text("I won't be at home"));
      await tester.pump();
      await tester.tap(inSheet('Cancel order'));
      await tester.pumpAndSettle();
      expect(repo.cancelled, [('o-1', null)]);
    });

    testWidgets('a paid order says how the refund works', (tester) async {
      await pump(
        tester,
        testOrder(
          method: PaymentMethod.online,
          paymentStatus: PaymentStatus.paid,
          paidPaise: 24800,
          pickupDate: today,
        ),
      );
      await openSheet(tester);
      expect(
        find.text(
          'You paid ₹248 online. After cancellation, contact support to confirm the refund status.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Keep order closes the sheet and changes nothing', (
      tester,
    ) async {
      final (_, repo, _) = await pump(tester, booked);
      await openSheet(tester);
      await tester.tap(find.text('Keep order'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this order?'), findsNothing);
      expect(repo.cancelled, isEmpty);
      expect(find.text('Step 1 of 5'), findsOneWidget);
    });

    testWidgets(
      'once picked up the API refuses: it says why and the sheet stays',
      (tester) async {
        final (_, repo, _) = await pump(tester, booked);
        repo.cancelFailure = const ApiFailure(
          ApiFailureKind.rejected,
          statusCode: 409,
          code: 'INVALID_TRANSITION',
        );
        await openSheet(tester);
        await tester.tap(inSheet('Cancel order'));
        await tester.pumpAndSettle();
        expect(find.textContaining('already been picked up'), findsOneWidget);
        expect(find.text('Cancel this order?'), findsOneWidget);
      },
    );

    testWidgets('offline says nothing was cancelled', (tester) async {
      final (_, repo, _) = await pump(tester, booked);
      repo.cancelFailure = const ApiFailure(ApiFailureKind.offline);
      await openSheet(tester);
      await tester.tap(inSheet('Cancel order'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining("You're offline. Nothing was cancelled"),
        findsOneWidget,
      );
    });

    testWidgets('after pickup there is no cancel button', (tester) async {
      await pump(
        tester,
        testOrder(
          status: OrderStatus.processing,
          pickedUpAt: pickedUp,
          method: PaymentMethod.online,
          paymentStatus: PaymentStatus.paid,
          paidPaise: 24800,
        ),
      );
      expect(find.text('Cancel order'), findsNothing);
    });

    testWidgets('a late pickup keeps Cancel order in its notice', (
      tester,
    ) async {
      final (_, repo, _) = await pump(
        tester,
        testOrder(
          pickupDate: today,
          dispatchFailedAt: DateTime.utc(2026, 10, 3, 9, 30),
        ),
      );
      expect(
        find.text('Free to cancel until your clothes are picked up.'),
        findsNothing,
        reason: 'no footer',
      );
      await openSheet(tester);
      await tester.tap(inSheet('Cancel order'));
      await tester.pumpAndSettle();
      expect(repo.cancelled, hasLength(1));
    });
  });

  group('paying what is due', () {
    final owing = testOrder(
      status: OrderStatus.processing,
      totalPaise: 18000,
      pieces: 12,
      pickedUpAt: pickedUp,
    );

    testWidgets(
      'the footer offers it, and Pay online goes to the payment in due mode',
      (tester) async {
        final (router, _, _) = await pump(tester, owing);
        await tester.tap(find.text('Pay ₹180 online'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Pay ₹180 for', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.text('12 items, ironed. Delivery Sun 4 Oct, 4 – 8 PM.'),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(FilledButton, 'Pay ₹180'));
        await tester.pumpAndSettle();
        expect(router.state.matchedLocation, '${Routes.order('o-1')}/pay');
        expect(router.state.uri.queryParameters['due'], '1');
        expect(find.text('PAY PAGE'), findsOneWidget);
      },
    );

    testWidgets('choosing cash on a cash order simply leaves it for the door', (
      tester,
    ) async {
      final (_, repo, _) = await pump(tester, owing);
      await tester.tap(find.text('Pay ₹180 online'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash at delivery'));
      await tester.pump();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Pay ₹180 in cash at delivery'),
      );
      await tester.pumpAndSettle();
      expect(repo.switchedToCash, isEmpty, reason: 'already cash on delivery');
      expect(find.text('Pay online now'), findsNothing);
    });

    testWidgets(
      'an online order that was never paid can be switched to cash from here',
      (tester) async {
        final (_, repo, _) = await pump(
          tester,
          testOrder(method: PaymentMethod.online, pickupDate: today),
        );
        await tester.tap(find.text('Pay ₹248'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cash at delivery'));
        await tester.pump();
        await tester.tap(
          find.widgetWithText(FilledButton, 'Pay ₹248 in cash at delivery'),
        );
        await tester.pumpAndSettle();

        expect(repo.switchedToCash, ['o-1']);
        expect(
          find.text('OK. Pay ₹248 in cash when your clothes are delivered.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('a paid order has nothing to pay', (tester) async {
      await pump(
        tester,
        testOrder(
          status: OrderStatus.processing,
          method: PaymentMethod.online,
          paymentStatus: PaymentStatus.paid,
          paidPaise: 24800,
          pickedUpAt: pickedUp,
        ),
      );
      expect(find.textContaining('Pay ₹'), findsNothing);
      expect(find.textContaining('is due'), findsNothing);
    });
  });

  testWidgets(
    'delivered clothes with an unpaid balance do not claim payment was received',
    (tester) async {
      await pump(
        tester,
        testOrder(
          status: OrderStatus.delivered,
          method: PaymentMethod.cod,
          paymentStatus: PaymentStatus.unpaid,
          paidPaise: 0,
        ),
      );
      expect(find.text('Payment due'), findsOneWidget);
      expect(find.text('₹248 due'), findsOneWidget);
      expect(find.text('Paid'), findsNothing);
      expect(find.text('₹248 in cash'), findsNothing);
    },
  );

  group('Book the same again', () {
    final delivered = testOrder(status: OrderStatus.delivered, pieces: 3);

    testWidgets('puts the items in the basket and opens it', (tester) async {
      final (router, _, container) = await pump(tester, delivered);
      await tester.tap(find.text('Book the same again'));
      await tester.pumpAndSettle();

      expect(container.read(basketProvider).lines, {'shirt': 3});
      expect(router.state.matchedLocation, Routes.basket);
    });

    testWidgets(
      'asks before replacing a basket that already has things in it',
      (tester) async {
        final (router, _, container) = await pump(
          tester,
          delivered,
          basket: {'basket.v1': '{"lines":{"saree":2},"promoCode":null}'},
        );
        await tester.tap(find.text('Book the same again'));
        await tester.pumpAndSettle();
        expect(find.text('Replace your basket?'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(container.read(basketProvider).lines, {'saree': 2});
        expect(router.state.matchedLocation, isNot(Routes.basket));

        await tester.tap(find.text('Book the same again'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Replace'));
        await tester.pumpAndSettle();
        expect(container.read(basketProvider).lines, {'shirt': 3});
        expect(router.state.matchedLocation, Routes.basket);
      },
    );
  });

  group('items and bill', () {
    testWidgets(
      'lists what was counted and adds the bill up, with what has been paid and what is due',
      (tester) async {
        final order = testOrder(
          status: OrderStatus.delivered,
          method: PaymentMethod.cod,
          paymentStatus: PaymentStatus.paid,
          paidPaise: 24800,
          pieces: 8,
          totalPaise: 24800,
          pickedUpAt: pickedUp,
          deliveredAt: DateTime.utc(2026, 10, 3, 12, 2),
        );
        final (router, _, _) = await pump(tester, order);
        unawaited(router.push(Routes.bill(order.id), extra: order));
        await tester.pumpAndSettle();

        expect(find.text('Items and bill'), findsWidgets);
        expect(find.text('Counted at pickup'), findsOneWidget);
        expect(find.text('8 × ₹15'), findsOneWidget);
        expect(find.text('₹120'), findsOneWidget);
        expect(find.text('Items (8)'), findsOneWidget);
        expect(find.text('Free'), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('Paid in cash'), findsOneWidget);
        expect(find.text('Due'), findsOneWidget);
        expect(
          find.text('Picked up Thu 1 Oct · Delivered Sat 3 Oct'),
          findsOneWidget,
        );
      },
    );
  });
}

String istTodayForTest() => DateTime.now()
    .toUtc()
    .add(const Duration(hours: 5, minutes: 30))
    .toIso8601String()
    .substring(0, 10);

class _Detail extends StatelessWidget {
  const _Detail();

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    return OrderDetailScreen(
      orderId: state.pathParameters['id']!,
      initial: state.extra as OrderDto?,
    );
  }
}

class _Bill extends StatelessWidget {
  const _Bill();

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    return OrderBillScreen(
      orderId: state.pathParameters['id']!,
      initial: state.extra as OrderDto?,
    );
  }
}

/// Orders built with a pickup partner or a cancel reason, which `testOrder` does not take directly.
extension on OrderDto {
  OrderDto withPickupDriver(PersonRefDto driver) => testOrder(
    id: id,
    number: orderNumber,
    status: status,
    totalPaise: totalPaise.toInt(),
    pieces: items.fold(0, (a, i) => a + i.quantity.toInt()),
    pickedUpAt: pickedUpAt,
    pickupDriver: driver,
    method: paymentMethod,
    paymentStatus: paymentStatus,
    paidPaise: paidPaise.toInt(),
  );

  OrderDto withCancelReason(String reason) => OrderDto(
    instructions: instructions,
    orderNumber: orderNumber,
    status: status,
    source: source,
    pickupDate: pickupDate,
    pickupSlot: pickupSlot,
    pickupSlotLabel: pickupSlotLabel,
    deliveryDate: deliveryDate,
    deliverySlot: deliverySlot,
    deliverySlotLabel: deliverySlotLabel,
    pickupAddress: pickupAddress,
    deliveryAddress: deliveryAddress,
    id: id,
    items: items,
    subtotalPaise: subtotalPaise,
    discountPaise: discountPaise,
    deliveryFeePaise: deliveryFeePaise,
    totalPaise: totalPaise,
    paidPaise: paidPaise,
    refundedPaise: refundedPaise,
    updatedAt: updatedAt,
    amountDuePaise: amountDuePaise,
    promoCode: promoCode,
    paymentMethod: paymentMethod,
    createdAt: createdAt,
    customer: customer,
    pickupDriver: pickupDriver,
    deliveryDriver: deliveryDriver,
    allowedNextStatuses: allowedNextStatuses,
    dispatchFailedAt: dispatchFailedAt,
    cancelReason: reason,
    pickedUpAt: pickedUpAt,
    deliveredAt: deliveredAt,
    cancelledAt: cancelledAt,
    paymentStatus: paymentStatus,
    events: events,
  );
}
