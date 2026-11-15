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
      expect(find.text('Accepted total: ₹248'), findsOneWidget);
      expect(find.text('New total: ₹496'), findsOneWidget);
      final button = find.text(approve ? 'Approve ₹496' : 'Decline new total');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(repo.calls, [approve]);
      expect(find.text('Review the new total'), findsNothing);
    });
  }
  testWidgets('a failed decision keeps both bills and allows retry at 200% text', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = Decisions()..fail = true;
    await tester.pumpWidget(themed(Scaffold(body: PriceApprovalCard(order: testOrder(adjustments: [request]))), textScale: 2,
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
}
