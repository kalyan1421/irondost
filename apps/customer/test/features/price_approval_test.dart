import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/orders/price_approval.dart';
import '../helpers.dart';

class Decisions implements AdjustmentRepository {
  final calls = <bool>[];
  bool fail = false;
  @override
  Future<OrderDto> decide(String orderId, String adjustmentId, {required bool approve}) async {
    calls.add(approve);
    if (fail) throw const ApiFailure(ApiFailureKind.offline);
    return testOrder();
  }
}

void main() {
  const line = AdjustmentLineDto(catalogItemId: 'shirt', name: 'Shirt', unit: ItemUnit.piece, unitPricePaise: 12400, quantity: 2, lineTotalPaise: 24800);
  final request = OrderAdjustmentDto(id: 'request', status: AdjustmentStatus.pendingCustomer, reason: 'Two extra shirts counted',
    oldTotalPaise: 24800, newTotalPaise: 49600, subtotalPaise: 49600, discountPaise: 0, deliveryFeePaise: 0,
    itemsBefore: [line], itemsAfter: [const AdjustmentLineDto(catalogItemId: 'shirt', name: 'Shirt', unit: ItemUnit.piece, unitPricePaise: 12400, quantity: 4, lineTotalPaise: 49600)],
    expiresAt: DateTime.utc(2099), decidedAt: null, createdAt: DateTime.utc(2026));
  for (final approve in [true, false]) {
    testWidgets('review shows both bills and records an explicit ${approve ? 'approval' : 'decline'}', (tester) async {
      final repo = Decisions();
      await tester.pumpWidget(themed(Scaffold(body: PriceApprovalCard(order: testOrder(adjustments: [request]))), overrides: [adjustmentRepositoryProvider.overrideWithValue(repo)]));
      await tester.tap(find.text('Review price change'));
      await tester.pumpAndSettle();
      expect(find.text('Accepted total'), findsOneWidget);
      expect(find.text('New total'), findsOneWidget);
      expect(find.text('2 → 4'), findsOneWidget, reason: 'the changed quantity is marked on its line');
      expect(find.text('+₹248'), findsOneWidget, reason: 'and the increase is stated once');
      expect(find.text('₹496'), findsNWidgets(3), reason: 'new line total, items subtotal and the new total');
      final button = find.text(approve ? 'Approve ₹496' : 'Decline new total');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(repo.calls, [approve]);
      expect(find.text('Review the new total'), findsNothing);
    });
  }
  testWidgets('the review lists added, removed and unchanged items, the discount and the travel charge', (tester) async {
    AdjustmentLineDto item(String id, String name, int rate, int qty) =>
        AdjustmentLineDto(catalogItemId: id, name: name, unit: ItemUnit.piece, unitPricePaise: rate, quantity: qty, lineTotalPaise: rate * qty);
    final mixed = OrderAdjustmentDto(id: 'mixed', status: AdjustmentStatus.pendingCustomer, reason: 'Counted again at the workshop',
      oldTotalPaise: 9000, newTotalPaise: 12500, subtotalPaise: 13500, discountPaise: 1500, deliveryFeePaise: 500,
      itemsBefore: [item('shirt', 'Shirt', 1500, 4), item('pants', 'Trousers', 3000, 1)],
      itemsAfter: [item('shirt', 'Shirt', 1500, 6), item('saree', 'Saree', 5000, 1), item('suit', 'Kurta', 500, 3)],
      expiresAt: DateTime.utc(2099), decidedAt: null, createdAt: DateTime.utc(2026));
    await tester.pumpWidget(themed(Scaffold(body: PriceApprovalCard(order: testOrder(deliveryFeePaise: 500, adjustments: [mixed]))),
      overrides: [adjustmentRepositoryProvider.overrideWithValue(Decisions())]));
    await tester.tap(find.text('Review price change'));
    await tester.pumpAndSettle();
    final sheet = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(find.text('Increase'), 200, scrollable: sheet);
    expect(find.text('4 → 6'), findsOneWidget);
    expect(find.text('New'), findsNWidgets(2), reason: 'two items are new');
    expect(find.text('Removed'), findsOneWidget);
    expect(find.text('Trousers'), findsOneWidget);
    expect(find.text('Discount'), findsOneWidget);
    expect(find.text('−₹15'), findsOneWidget);
    expect(find.text('Travel charge'), findsOneWidget);
    expect(find.text('₹5'), findsWidgets, reason: 'the travel charge is shown as an amount, not Free');
    expect(find.text('Free'), findsNothing);
    expect(find.text('+₹35'), findsOneWidget);
  });

  testWidgets('a failed decision keeps both bills and allows retry at 200% text', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = Decisions()..fail = true;
    // On the order screen the card sits in a scrolling list; at 200% text it is taller than this small screen.
    await tester.pumpWidget(themed(Scaffold(body: SingleChildScrollView(child: PriceApprovalCard(order: testOrder(adjustments: [request])))), textScale: 2,
      overrides: [adjustmentRepositoryProvider.overrideWithValue(repo)]));
    await tester.ensureVisible(find.text('Review price change'));
    await tester.tap(find.text('Review price change'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Approve ₹496'));
    await tester.tap(find.text('Approve ₹496'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not save your decision'), findsOneWidget);
    expect(tester.takeException(), isNull);
    repo.fail = false;
    await tester.ensureVisible(find.text('Decline new total'));
    await tester.tap(find.text('Decline new total'));
    await tester.pumpAndSettle();
    expect(repo.calls, [true, false]);
  });

  group('the travel charge in the review', () {
    const small = AdjustmentLineDto(catalogItemId: 'shirt', name: 'Shirt', unit: ItemUnit.piece, unitPricePaise: 10000, quantity: 1, lineTotalPaise: 10000);
    const big = AdjustmentLineDto(catalogItemId: 'shirt', name: 'Shirt', unit: ItemUnit.piece, unitPricePaise: 10000, quantity: 2, lineTotalPaise: 20000);
    OrderAdjustmentDto asked({required int fee, required AdjustmentLineDto before, required AdjustmentLineDto after, required int oldTotal}) => OrderAdjustmentDto(
      id: 'travel', status: AdjustmentStatus.pendingCustomer, reason: 'Counted again at pickup',
      oldTotalPaise: oldTotal, newTotalPaise: after.lineTotalPaise + fee, subtotalPaise: after.lineTotalPaise, discountPaise: 0, deliveryFeePaise: fee,
      itemsBefore: [before], itemsAfter: [after], expiresAt: DateTime.utc(2099), decidedAt: null, createdAt: DateTime.utc(2026));

    Future<void> open(WidgetTester tester, OrderDto order) async {
      await tester.pumpWidget(themed(Scaffold(body: PriceApprovalCard(order: order)),
        overrides: [adjustmentRepositoryProvider.overrideWithValue(Decisions())]));
      await tester.tap(find.text('Review price change'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Increase'), 200, scrollable: find.byType(Scrollable).last);
    }

    bool rich(String text) => find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == text).evaluate().isNotEmpty;

    testWidgets('shows the charge going away when more clothes reach the free amount', (tester) async {
      // Booked as one shirt (₹100 and a ₹30 charge); counted as two (₹200, free). The total still goes up, so it asks.
      final request = asked(fee: 0, before: small, after: big, oldTotal: 13000);
      await open(tester, testOrder(deliveryFeePaise: 3000, totalPaise: 13000, adjustments: [request]));
      expect(find.text('Travel charge'), findsOneWidget);
      expect(rich('₹30 Free'), isTrue, reason: 'the old charge, then the new one');
      expect(find.bySemanticsLabel(RegExp('Free, was ₹30')), findsOneWidget);
      expect(find.text('+₹70'), findsOneWidget);
      expect(find.text('Approve ₹200'), findsOneWidget);
    });

    testWidgets('shows the charge coming in when the count falls under the free amount', (tester) async {
      final request = asked(fee: 3000, before: big, after: small, oldTotal: 12000);
      await open(tester, testOrder(deliveryFeePaise: 0, totalPaise: 12000, adjustments: [request]));
      expect(rich('Free ₹30'), isTrue);
    });

    testWidgets('shows a plain line when the charge did not move', (tester) async {
      final request = asked(fee: 3000, before: small, after: big, oldTotal: 13000);
      await open(tester, testOrder(deliveryFeePaise: 3000, totalPaise: 13000, adjustments: [request]));
      expect(find.text('Travel charge'), findsOneWidget);
      expect(find.text('₹30'), findsOneWidget);
      expect(rich('₹30 ₹30'), isFalse);
    });
  });
}
