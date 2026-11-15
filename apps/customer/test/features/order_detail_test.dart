import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/core/slots.dart';
import 'package:irondost_customer/core/text_wrap.dart';
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
  // A delivery window that is today ends at 8 PM, and after that the screen rightly says the estimate was missed.
  // Tests of an order still on its way use tomorrow, so they do not depend on the time of day they run.
  final tomorrow = DateTime.parse('${today}T00:00:00Z').add(const Duration(days: 1)).toIso8601String().substring(0, 10);
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
      expect(find.text('Pay ₹180 online'), findsOneWidget);
      expect(find.text('Or pay the partner in cash when your clothes come back.'), findsOneWidget);
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
        deliveryDate: tomorrow,
        pickedUpAt: pickedUp,
        deliveryDriver: ravi,
      ),
    );
    expect(find.text('Out for delivery'), findsWidgets);
    expect(find.text('Arriving tomorrow, 4\u00A0\u2060–\u2060\u00A08\u00A0PM'), findsOneWidget);
    expect(find.text('Bringing your clothes back'), findsOneWidget);
    expect(find.text('Or pay Ravi in cash at the door.'), findsOneWidget);
  });

  group('the status hero and the partner card', () {
    /// The five-segment bar that used to repeat the timeline: any 4 dp tall container.
    int barSegments(WidgetTester tester) => tester
        .widgetList<Container>(
          find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.minHeight == 4 &&
                w.constraints?.maxHeight == 4,
          ),
        )
        .length;

    Finder callButtons() => find.byWidgetPredicate(
      (w) => w is IconButton && (w.tooltip ?? '').startsWith('Call '),
    );

    testWidgets('progress is the words and the timeline, with no second bar, and nothing to call about while on time', (
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

      expect(barSegments(tester), 0);
      expect(find.text('Step 3 of 5'), findsOneWidget);
      expect(find.text('Call us'), findsNothing, reason: 'nothing is late');
    });

    testWidgets('a missed delivery estimate is one notice that holds the sentence and the call', (
      tester,
    ) async {
      await pump(
        tester,
        testOrder(
          status: OrderStatus.processing,
          pickedUpAt: pickedUp,
        ).withPickupDriver(ravi),
      );

      expect(barSegments(tester), 0);
      expect(find.textContaining('Delivery estimate missed:'), findsOneWidget);
      expect(find.text('Call us'), findsOneWidget);
      final amber = tester.element(find.byType(Scaffold).first).colors.warningSoft;
      final panel = find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).color == amber);
      expect(find.descendant(of: panel.first, matching: find.textContaining('Delivery estimate missed:')), findsOneWidget);
      expect(find.descendant(of: panel.first, matching: find.text('Call us')), findsOneWidget,
        reason: 'the call is inside the same amber panel as the sentence, not a button floating below it');
    });

    testWidgets('a late pickup still has exactly one Call us', (
      tester,
    ) async {
      await pump(
        tester,
        testOrder(
          pickupDate: today,
          dispatchFailedAt: DateTime.utc(2026, 10, 3, 9, 30),
        ),
      );

      expect(barSegments(tester), 0);
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
      expect(find.text('Pay ₹248'), findsOneWidget);
      expect(find.text('Not paid yet. You can also switch to cash on delivery.'), findsOneWidget);
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
      expect(find.text('12 items'), findsOneWidget);
    expect(find.text('₹180 · Paid in cash'), findsOneWidget);
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
    expect(find.text(keepLastWordsTogether('You cancelled this order')), findsOneWidget);
    expect(
      find.text('Fri 2 Oct, 2:14 PM · "I booked by mistake"'),
      findsOneWidget,
    );
    expect(
      find.textContaining('₹248 has no confirmed refund'),
      findsOneWidget,
    );
    expect(find.text('Paid'), findsOneWidget, reason: 'the line no longer claims a refund state the notice above denies');
    expect(find.textContaining('refund pending'), findsNothing);
    expect(find.text('Book again'), findsOneWidget);
  });

  testWidgets('being ironed with no partner on record shows no placeholder to wait for', (tester) async {
    await pump(tester, testOrder(status: OrderStatus.processing, pickedUpAt: pickedUp));
    expect(find.text('Your partner'), findsNothing);
    expect(find.textContaining("You'll see your partner's name"), findsNothing);
  });

  testWidgets('delivered without a pickup time has no Picked up row with a dash in it', (tester) async {
    await pump(tester, testOrder(status: OrderStatus.delivered, paymentStatus: PaymentStatus.paid, paidPaise: 24800, deliveredAt: DateTime.utc(2026, 10, 4, 12)));
    expect(find.text('Picked up'), findsNothing);
    expect(find.text('—'), findsNothing);
    expect(find.text('Count'), findsOneWidget);
  });

  group('cancelled and paid, with refund records', () {
    RefundDto refund(RefundStatus status, {int amount = 24800}) => RefundDto(id: 'r-$status', amountPaise: amount, method: RefundMethod.razorpay,
      status: status, note: 'Order cancelled before collection.', createdAt: DateTime.utc(2026, 10, 2, 9), processedAt: null, failureReason: null);
    OrderDto cancelled(List<RefundDto> refunds) => testOrder(status: OrderStatus.cancelled, method: PaymentMethod.online,
      paymentStatus: PaymentStatus.paid, paidPaise: 24800, refundedPaise: 24800, refunds: refunds);

    testWidgets('a pending refund is one row with its state, and no second sentence repeats it', (tester) async {
      await pump(tester, cancelled([refund(RefundStatus.pending)]));
      expect(find.text('Refund'), findsOneWidget, reason: 'the row says what it is');
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('₹248'), findsNWidgets(2), reason: 'the refund row, and what was paid');
      expect(find.textContaining('Original online payment'), findsOneWidget);
      expect(find.text('Order cancelled before collection.'), findsOneWidget);
      expect(find.textContaining('refund pending'), findsNothing);
      expect(find.textContaining('has no confirmed refund'), findsNothing);
    });

    testWidgets('a completed refund says Completed, a failed one says to contact support', (tester) async {
      await pump(tester, cancelled([refund(RefundStatus.processed)]));
      expect(find.text('Completed'), findsOneWidget);
      await pump(tester, cancelled([refund(RefundStatus.failed)]));
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('The refund did not complete. Contact support.'), findsOneWidget);
    });

    group('with the travel charge kept', () {
      // Paid ₹248, of which ₹30 is the travel charge staff kept because the partner had already travelled.
      OrderDto keptCharge({int refundedPaise = 21800, int paidPaise = 24800, bool kept = true}) => testOrder(status: OrderStatus.cancelled,
        method: PaymentMethod.online, paymentStatus: PaymentStatus.paid, paidPaise: paidPaise, refundedPaise: refundedPaise,
        deliveryFeePaise: 3000, travelChargeKept: kept, refunds: [if (refundedPaise > 0) refund(RefundStatus.processed, amount: refundedPaise)]);

      testWidgets('says why and how much, and does not call the kept charge a missing refund', (tester) async {
        await pump(tester, keptCharge());
        expect(find.text(keepLastWordsTogether('Travel charge kept: partner had already travelled')), findsOneWidget);
        expect(find.text('Kept for travel'), findsOneWidget);
        expect(find.text('₹30'), findsOneWidget);
        expect(find.text('₹218'), findsOneWidget, reason: 'the refund row: everything paid except the charge');
        expect(find.textContaining('has no confirmed refund'), findsNothing);
      });

      testWidgets('while the rest is still on its way it calls out only what is owed back', (tester) async {
        await pump(tester, keptCharge(refundedPaise: 0));
        expect(find.textContaining('₹218 has no confirmed refund'), findsOneWidget, reason: '₹248 paid less the ₹30 kept');
        expect(find.text(keepLastWordsTogether('Travel charge kept: partner had already travelled')), findsOneWidget);
      });

      testWidgets('is silent when the charge was refunded with everything else', (tester) async {
        await pump(tester, keptCharge(kept: false, refundedPaise: 24800));
        expect(find.textContaining('Travel charge kept'), findsNothing);
        expect(find.text('Kept for travel'), findsNothing);
      });

      testWidgets('is silent when nothing was paid: an unpaid order was not charged', (tester) async {
        await pump(tester, testOrder(status: OrderStatus.cancelled, deliveryFeePaise: 3000, travelChargeKept: true));
        expect(find.textContaining('Travel charge kept'), findsNothing);
        expect(find.textContaining('nothing charged'), findsOneWidget);
      });
    });

    testWidgets('money that no refund accounts for is still called out beside the rows', (tester) async {
      await pump(tester, cancelled([refund(RefundStatus.processed, amount: 10000)]));
      expect(find.text('Completed'), findsOneWidget);
      expect(find.textContaining('₹148 has no confirmed refund'), findsOneWidget);
    });
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
        expect(find.text(keepLastWordsTogether('You cancelled this order')), findsOneWidget);
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
          find.text(keepWindowTogether('12 items. Delivery Sun 4 Oct, 4 – 8 PM.')),
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
        expect(find.text('8 × ₹15 per piece'), findsOneWidget);
        expect(find.text('₹120'), findsOneWidget);
        expect(find.text('Items (8)'), findsOneWidget);
        expect(find.text('Travel charge'), findsOneWidget);
        expect(find.text('Pickup & delivery'), findsNothing);
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

    testWidgets('a small order shows the charge as an amount in the bill', (tester) async {
      final order = testOrder(
        status: OrderStatus.delivered,
        paymentStatus: PaymentStatus.paid,
        paidPaise: 15000,
        pieces: 8,
        totalPaise: 15000,
        deliveryFeePaise: 3000,
        pickedUpAt: pickedUp,
        deliveredAt: DateTime.utc(2026, 10, 3, 12, 2),
      );
      final (router, _, _) = await pump(tester, order);
      unawaited(router.push(Routes.bill(order.id), extra: order));
      await tester.pumpAndSettle();

      expect(find.text('Travel charge'), findsOneWidget);
      expect(find.text('₹30'), findsOneWidget);
      expect(find.text('Free'), findsNothing);
      expect(find.text('₹120'), findsNWidgets(2), reason: 'the item line and the Items row: the total less the travel charge');
    });

    testWidgets('a cancelled order says the kept charge was kept because the partner had already travelled', (tester) async {
      final order = testOrder(
        status: OrderStatus.cancelled,
        method: PaymentMethod.online,
        paymentStatus: PaymentStatus.paid,
        paidPaise: 15000,
        refundedPaise: 12000,
        pieces: 8,
        totalPaise: 15000,
        deliveryFeePaise: 3000,
        travelChargeKept: true,
      );
      final (router, _, _) = await pump(tester, order);
      unawaited(router.push(Routes.bill(order.id), extra: order));
      await tester.pumpAndSettle();

      expect(find.text('Travel charge'), findsOneWidget);
      expect(find.text(keepLastWordsTogether('Kept: partner had already travelled')), findsOneWidget);
    });
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
    careNote: careNote,
    carePhotoUrls: carePhotoUrls,
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
    travelChargeKept: travelChargeKept,
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
    rescheduleCount: rescheduleCount,
    reschedulesRemaining: reschedulesRemaining,
    canReschedule: canReschedule,
    paymentStatus: paymentStatus,
    events: events,
  );
}
