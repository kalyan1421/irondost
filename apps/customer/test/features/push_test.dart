import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/features/basket/basket.dart';
import 'package:irondost_customer/features/notifications/notifications.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/push/device_registrar.dart';
import 'package:irondost_customer/features/push/notification_permission_screen.dart';
import 'package:irondost_customer/features/push/push_handler.dart';
import 'package:irondost_customer/features/push/push_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

class _FakePush implements PushSource {
  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();
  PushMessage? launch;
  PushPermission current = PushPermission.notDetermined;
  PushPermission answer = PushPermission.granted;
  int asked = 0;

  @override
  Stream<PushMessage> get foreground => _foreground.stream;

  @override
  Stream<PushMessage> get opened => _opened.stream;

  @override
  Future<PushMessage?> launchedBy() async => launch;

  @override
  Future<PushPermission> permission() async => current;

  @override
  Future<PushPermission> request() async {
    asked++;
    return current = answer;
  }

  void arrive(PushMessage m) => _foreground.add(m);
  void tap(PushMessage m) => _opened.add(m);
}

class _FakeRegistrar implements DeviceRegistrar {
  int registered = 0;

  @override
  Future<void> register() async => registered++;

  @override
  Future<void> unregister() async {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  const onTheWay = PushMessage(title: 'Partner on the way', body: 'Ravi is coming.', data: {'type': 'order_status', 'orderId': 'o-1', 'status': 'PICKUP_ASSIGNED'});

  test('a notification opens its order, the offers, or else the inbox', () {
    expect(routeForPush(onTheWay), Routes.order('o-1'));
    expect(routeForPush(const PushMessage(data: {'type': 'promo'})), Routes.offers);
    expect(routeForPush(const PushMessage(data: {'type': 'order_offer_x'})), Routes.offers);
    expect(routeForPush(const PushMessage()), Routes.notifications);
    expect(routeForPush(const PushMessage(data: {'orderId': ''})), Routes.notifications);
  });

  group('while the app is open', () {
    late _FakePush push;
    late FakeOrderRepository orders;
    late FakeNotificationRepository inbox;

    Future<ProviderContainer> open() async {
      push = _FakePush();
      orders = FakeOrderRepository();
      inbox = FakeNotificationRepository();
      final c = ProviderContainer(
        overrides: [
          ...await basketOverrides(),
          pushSourceProvider.overrideWithValue(push),
          orderRepositoryProvider.overrideWithValue(orders),
          notificationRepositoryProvider.overrideWithValue(inbox),
        ],
      );
      addTearDown(c.dispose);
      c
        ..listen(pushHandlerProvider, (_, _) {})
        ..listen(notificationsProvider, (_, _) {})
        ..listen(orderProvider('o-1'), (_, _) {});
      await c.read(notificationsProvider.future);
      await Future<void>.delayed(Duration.zero);
      return c;
    }

    test('a push that arrives refreshes the inbox and its order, and is offered as a banner', () async {
      final c = await open();
      final asked = inbox.listAsked.length;
      final gets = orders.getCount;

      push.arrive(onTheWay);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(inbox.listAsked.length, asked + 1);
      expect(orders.getCount, gets + 1);
      expect(c.read(inAppPushProvider)?.title, 'Partner on the way');
    });

    test('a tap while in the background asks to open where it points', () async {
      final c = await open();
      push.tap(onTheWay);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(pushTapProvider), Routes.order('o-1'));
      c.read(pushTapProvider.notifier).done();
      expect(c.read(pushTapProvider), isNull);
    });

    test('starting the app by tapping a notification opens it too', () async {
      push = _FakePush()..launch = onTheWay;
      final c = ProviderContainer(overrides: [...await basketOverrides(), pushSourceProvider.overrideWithValue(push)]);
      addTearDown(c.dispose);
      c.listen(pushHandlerProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.read(pushTapProvider), Routes.order('o-1'));
    });
  });

  group('offering notifications', () {
    Future<(ProviderContainer, _FakePush, _FakeRegistrar)> open({PushPermission permission = PushPermission.notDetermined, Map<String, Object> saved = const {}}) async {
      SharedPreferences.setMockInitialValues(saved);
      final prefs = await SharedPreferences.getInstance();
      final push = _FakePush()..current = permission;
      final registrar = _FakeRegistrar();
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs), pushSourceProvider.overrideWithValue(push), deviceRegistrarProvider.overrideWithValue(registrar)],
      );
      addTearDown(c.dispose);
      return (c, push, registrar);
    }

    test('offered while the system prompt can still be shown, and only until the customer has answered', () async {
      var (c, _, _) = await open();
      expect(await c.read(pushOfferProvider).shouldOffer(), isTrue);

      (c, _, _) = await open(permission: PushPermission.granted);
      expect(await c.read(pushOfferProvider).shouldOffer(), isFalse);
      (c, _, _) = await open(permission: PushPermission.denied);
      expect(await c.read(pushOfferProvider).shouldOffer(), isFalse);
      (c, _, _) = await open(saved: {'push.asked.v1': true});
      expect(await c.read(pushOfferProvider).shouldOffer(), isFalse, reason: 'already said Not now');
    });

    test('turning on asks the system and registers this phone, once', () async {
      final (c, push, registrar) = await open();
      expect(await c.read(pushOfferProvider).turnOn(), PushPermission.granted);
      await Future<void>.delayed(Duration.zero);
      expect(push.asked, 1);
      expect(registrar.registered, 1);
      expect(await c.read(pushOfferProvider).shouldOffer(), isFalse);
    });

    test('a refusal registers nothing and is not asked again', () async {
      final (c, push, registrar) = await open();
      push.answer = PushPermission.denied;
      expect(await c.read(pushOfferProvider).turnOn(), PushPermission.denied);
      expect(registrar.registered, 0);
      expect(await c.read(pushOfferProvider).shouldOffer(), isFalse);
    });

    test('a phone without push is simply not offered it', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), pushSourceProvider.overrideWithValue(_Broken())]);
      addTearDown(c.dispose);
      expect(await c.read(pushOfferProvider).shouldOffer(), isFalse);
    });
  });

  group('the permission screen', () {
    Future<(GoRouter, _FakePush, _FakeRegistrar, SharedPreferences)> pump(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 844 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final push = _FakePush();
      final registrar = _FakeRegistrar();
      final router = testRouter(
        {
          '/after': () => Scaffold(body: Center(child: Builder(builder: (context) => TextButton(onPressed: () => context.push(Routes.notificationPermission), child: const Text('OPEN')))), ),
          Routes.notificationPermission: () => const NotificationPermissionScreen(),
        },
        initial: '/after',
      );
      await tester.pumpWidget(themedRouter(router, overrides: [sharedPreferencesProvider.overrideWithValue(prefs), pushSourceProvider.overrideWithValue(push), deviceRegistrarProvider.overrideWithValue(registrar)]));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      return (router, push, registrar, prefs);
    }

    testWidgets('explains why, and Turn on asks the system then leaves', (tester) async {
      final (router, push, registrar, _) = await pump(tester);
      expect(find.text("Know when we're at your door"), findsOneWidget);
      expect(find.textContaining('Offers only if you want them'), findsOneWidget);

      await tester.tap(find.text('Turn on notifications'));
      await tester.pumpAndSettle();
      expect(push.asked, 1);
      expect(registrar.registered, 1);
      expect(router.state.matchedLocation, '/after');
    });

    testWidgets('Not now leaves without asking the system, and is remembered', (tester) async {
      final (router, push, registrar, prefs) = await pump(tester);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(push.asked, 0);
      expect(registrar.registered, 0);
      expect(prefs.getBool('push.asked.v1'), isTrue);
      expect(router.state.matchedLocation, '/after');
    });
  });
}

class _Broken implements PushSource {
  @override
  Stream<PushMessage> get foreground => const Stream.empty();

  @override
  Stream<PushMessage> get opened => const Stream.empty();

  @override
  Future<PushMessage?> launchedBy() async => null;

  @override
  Future<PushPermission> permission() => throw StateError('no push here');

  @override
  Future<PushPermission> request() => throw StateError('no push here');
}
