import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/core/order_timeline.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/design/widgets/service_art.dart';
import 'package:irondost_customer/features/orders/order_detail_screen.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/orders/price_approval.dart';
import 'package:irondost_customer/features/support/support.dart';

import '../helpers.dart';

final _pending = OrderAdjustmentDto(
  id: 'request',
  status: AdjustmentStatus.pendingCustomer,
  reason: 'Two extra shirts counted',
  oldTotalPaise: 24800,
  newTotalPaise: 49600,
  subtotalPaise: 49600,
  discountPaise: 0,
  deliveryFeePaise: 0,
  itemsBefore: const [],
  itemsAfter: const [],
  expiresAt: DateTime.utc(2099),
  decidedAt: null,
  createdAt: DateTime.utc(2026),
);

void main() {
  group('what is happening now', () {
    test('every status has its own line', () {
      final lines = {
        for (final s in OrderStatus.values.where((s) => s != OrderStatus.$unknown)) nowLine(testOrder(status: s)),
      };
      expect(lines, hasLength(OrderStatus.values.length - 1));
      expect(nowLine(testOrder(status: OrderStatus.processing)), 'Your clothes are being washed, ironed and cared for');
    });

    test('each stage offers its action, and a waiting price comes first', () {
      expect(stageAction(testOrder()), StageAction.careNote);
      expect(stageAction(testOrder(status: OrderStatus.pickupAssigned)), StageAction.careNote);
      expect(stageAction(testOrder(status: OrderStatus.processing)), isNull);
      expect(stageAction(testOrder(status: OrderStatus.processing, adjustments: [_pending])), StageAction.approvePrice);
      expect(stageAction(testOrder(status: OrderStatus.delivered)), StageAction.reportIssue);
    });
  });

  group('illustrated stages on the order', () {
    late List<Uri> launched;

    Future<GoRouter> pump(WidgetTester tester, OrderDto order) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 1600 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      launched = [];
      final router = GoRouter(
        initialLocation: Routes.order(order.id),
        initialExtra: order,
        routes: [
          GoRoute(path: Routes.orderDetail, builder: (_, s) => OrderDetailScreen(orderId: s.pathParameters['id']!, initial: s.extra as OrderDto?)),
          GoRoute(path: Routes.reportProblem, builder: (_, _) => const Text('REPORT PAGE')),
          GoRoute(path: Routes.orders, builder: (_, _) => const Text('ORDERS PAGE')),
        ],
      );
      await tester.pumpWidget(themedRouter(router, overrides: [
        ...await basketOverrides(),
        orderRepositoryProvider.overrideWithValue(FakeOrderRepository()..orders[order.id] = order),
        adjustmentRepositoryProvider.overrideWithValue(_NoDecisions()),
        supportLauncherProvider.overrideWithValue((uri) async {
          launched.add(uri);
          return true;
        }),
      ]));
      await tester.pumpAndSettle();
      return router;
    }

    double opacityOf(WidgetTester tester, int step, String state) =>
        tester.widget<Opacity>(find.byKey(ValueKey('stage-art-$step-$state'))).opacity;

    testWidgets('pictures fill in as stages are reached; the current one says what is happening', (tester) async {
      await pump(tester, testOrder(status: OrderStatus.processing, pickedUpAt: DateTime.utc(2026, 10, 1, 12)));
      expect(opacityOf(tester, 0, 'done'), 1);
      expect(opacityOf(tester, 1, 'done'), 1);
      expect(opacityOf(tester, 2, 'current'), 1);
      expect(opacityOf(tester, 3, 'future'), lessThan(1));
      expect(opacityOf(tester, 4, 'future'), lessThan(1));
      final art = tester.widgetList<ServiceArtImage>(find.byType(ServiceArtImage)).map((a) => a.art).toList();
      expect(art, [ServiceArt.pickupBag, ServiceArt.laundry, ServiceArt.ironing, ServiceArt.washFold, ServiceArt.shirt]);
      expect(find.text('Your clothes are being washed, ironed and cared for'), findsOneWidget);
    });

    testWidgets('before pickup: add a care note, sent on WhatsApp with the order number', (tester) async {
      await pump(tester, testOrder());
      expect(find.text("We're lining up a partner to collect your clothes"), findsOneWidget);
      await tester.tap(find.text('Add a care note'));
      await tester.pumpAndSettle();
      expect(launched.single.queryParameters['text'], 'Order ID001046 care note: ');
    });

    testWidgets('a waiting price change: approve it from the stage', (tester) async {
      await pump(tester, testOrder(status: OrderStatus.processing, adjustments: [_pending]));
      await tester.tap(find.text('Review the new price'));
      await tester.pumpAndSettle();
      expect(find.text('Accepted total'), findsOneWidget);
    });

    testWidgets('after delivery: report an issue', (tester) async {
      final router = await pump(tester, testOrder(status: OrderStatus.delivered, deliveredAt: DateTime.utc(2026, 10, 3, 12)));
      expect(find.text('Delivered: fresh clothes, ready to wear'), findsOneWidget);
      await tester.tap(find.text('Report an issue'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.report('o-1'));
    });
  });
}

class _NoDecisions implements AdjustmentRepository {
  @override
  Future<OrderDto> decide(String orderId, String adjustmentId, {required bool approve}) => throw UnimplementedError();
}
