import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/addresses/address_repository.dart';
import 'package:irondost_customer/features/home/first_pickup.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/orders/orders_list.dart';
import 'package:irondost_customer/features/push/push_source.dart';

import '../helpers.dart';

class _Push implements PushSource {
  _Push(this.current);
  PushPermission current;

  @override
  Stream<PushMessage> get foreground => const Stream.empty();
  @override
  Stream<PushMessage> get opened => const Stream.empty();
  @override
  Future<PushMessage?> launchedBy() async => null;
  @override
  Future<PushPermission> permission() async => current;
  @override
  Future<PushPermission> request() async => current;
}

void main() {
  group('the checklist', () {
    const empty = OrderList(items: [], total: 0);
    List<FirstPickupItem>? list({OrderList? active = empty, OrderList? past = empty}) => firstPickupChecklist(
          active: active,
          past: past,
          hasAddress: true,
          notificationsOn: false,
          basketStarted: true,
          slotPicked: false,
          careNote: false,
        );

    test('ticks come from what the app holds; the care note is optional', () {
      final items = list()!;
      expect([for (final i in items) i.done], [true, false, true, false, false]);
      expect([for (final i in items) i.optional], [false, false, false, false, true]);
    });

    test('gone once an order is delivered, hidden while one is on its way or the orders are loading', () {
      expect(list(past: OrderList(items: [testOrder(status: OrderStatus.delivered)], total: 1)), isNull);
      expect(list(active: OrderList(items: [testOrder()], total: 1)), isNull);
      expect(list(active: null), isNull);
      expect(list(past: null), isNull);
      // A cancelled order is not a first pickup: the card stays.
      expect(list(past: OrderList(items: [testOrder(status: OrderStatus.cancelled)], total: 1)), isNotNull);
    });
  });

  group('Ready for your first pickup?', () {
    Future<GoRouter> pump(
      WidgetTester tester, {
      List<OrderDto> orders = const [],
      PushPermission push = PushPermission.notDetermined,
      Map<String, Object> saved = const {},
    }) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 1000 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final router = testRouter({
        Routes.home: () => ListView(children: const [FirstPickupCard()]),
        Routes.book: () => const Text('CATALOGUE PAGE'),
        Routes.schedule: () => const Text('SCHEDULE PAGE'),
        Routes.notificationPermission: () => const Text('PERMISSION PAGE'),
        Routes.addresses: () => const Text('ADDRESSES PAGE'),
      }, initial: Routes.home);
      await tester.pumpWidget(
        themedRouter(
          router,
          overrides: [
            ...await basketOverrides(saved: saved),
            orderRepositoryProvider.overrideWithValue(FakeOrderRepository()..listed.addAll(orders)),
            addressRepositoryProvider.overrideWithValue(FakeAddressRepository([testAddress()])),
            pushSourceProvider.overrideWithValue(_Push(push)),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    bool ticked(WidgetTester tester, String label) =>
        tester.getSemantics(find.bySemanticsLabel(RegExp('^$label'))).label.endsWith(', done');

    testWidgets('a new customer sees what is done and what is left', (tester) async {
      await pump(tester, push: PushPermission.granted);
      expect(find.text('Ready for your first pickup?'), findsOneWidget);
      expect(find.text('2 steps to go'), findsOneWidget);
      expect(ticked(tester, 'Address saved'), isTrue);
      expect(ticked(tester, 'Notifications on'), isTrue);
      expect(ticked(tester, 'Basket started'), isFalse);
      expect(ticked(tester, 'Time window picked'), isFalse);
      expect(find.bySemanticsLabel('Care note, optional, not done yet'), findsOneWidget);
    });

    testWidgets('a started basket is ticked, and the time row opens the time picker', (tester) async {
      final router = await pump(tester, saved: {'basket.v1': '{"lines":{"shirt":2}}'});
      expect(ticked(tester, 'Basket started'), isTrue);
      await tester.tap(find.text('Time window picked'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.schedule);
    });

    testWidgets('each row opens its screen', (tester) async {
      final router = await pump(tester);
      await tester.tap(find.text('Basket started'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.book);
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Time window picked'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.book, reason: 'no basket yet, so items come first');
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notifications on'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.notificationPermission);
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Address saved'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.addresses);
    });

    testWidgets('gone after the first delivery', (tester) async {
      await pump(tester, orders: [testOrder(status: OrderStatus.delivered)]);
      expect(find.text('Ready for your first pickup?'), findsNothing);
    });
  });
}
