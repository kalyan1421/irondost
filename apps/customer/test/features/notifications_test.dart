import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/provider_retry.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/core/slots.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/auth/session.dart';
import 'package:irondost_customer/features/notifications/notifications.dart';
import 'package:irondost_customer/features/notifications/notifications_screen.dart';

import '../helpers.dart';

void main() {
  group('the inbox', () {
    late FakeNotificationRepository repo;

    ProviderContainer open() {
      repo = FakeNotificationRepository();
      final c = ProviderContainer(
        retry: noAutomaticRetry,
        overrides: [notificationRepositoryProvider.overrideWithValue(repo), sessionProvider.overrideWith(SignedInSession.new)],
      );
      addTearDown(c.dispose);
      c.listen(notificationsProvider, (_, _) {});
      return c;
    }

    List<NotificationDto> many(int n) => [for (var i = 0; i < n; i++) testNotification('n$i', readAt: i.isEven ? null : DateTime.now())];

    test('loads the first page with how many are unread', () async {
      final c = open();
      repo.inbox.addAll(many(5));
      final list = await c.read(notificationsProvider.future);
      expect(list.items, hasLength(5));
      expect(list.unread, 3);
      expect(c.read(unreadCountProvider), 3);
    });

    test('marking one read is instant, tells the server once, and counts down', () async {
      final c = open();
      repo.inbox.addAll(many(3));
      await c.read(notificationsProvider.future);

      await c.read(notificationsProvider.notifier).markRead('n0');
      var list = c.read(notificationsProvider).requireValue;
      expect(list.items.first.readAt, isNotNull);
      expect(list.unread, 1);
      expect(repo.markedRead, ['n0']);

      await c.read(notificationsProvider.notifier).markRead('n0'); // already read: nothing more
      await c.read(notificationsProvider.notifier).markRead('n1'); // was read already
      expect(repo.markedRead, ['n0']);
      list = c.read(notificationsProvider).requireValue;
      expect(list.unread, 1);
    });

    test('mark all read clears every dot at once', () async {
      final c = open();
      repo.inbox.addAll(many(4));
      await c.read(notificationsProvider.future);
      await c.read(notificationsProvider.notifier).markAllRead();
      final list = c.read(notificationsProvider).requireValue;
      expect(list.unread, 0);
      expect(list.items.every((n) => n.readAt != null), isTrue);
      expect(repo.markedAll, 1);
    });

    test('a server that does not answer does not undo what the customer sees', () async {
      final c = open();
      repo.inbox.addAll(many(3));
      await c.read(notificationsProvider.future);
      repo.markFailure = const ApiFailure(ApiFailureKind.offline);
      await c.read(notificationsProvider.notifier).markRead('n0');
      expect(c.read(notificationsProvider).requireValue.items.first.readAt, isNotNull);
    });

    test('loads further pages, once each', () async {
      final c = open();
      repo.inbox.addAll(many(45));
      await c.read(notificationsProvider.future);
      final notifier = c.read(notificationsProvider.notifier);
      await Future.wait([notifier.loadMore(), notifier.loadMore()]);
      expect(c.read(notificationsProvider).requireValue.items, hasLength(40));
      expect(repo.listAsked.where((p) => p == 2), hasLength(1));
      await notifier.loadMore();
      expect(c.read(notificationsProvider).requireValue.items, hasLength(45));
    });

    test('knows which order a notification is about', () {
      expect(notificationOrderId(testNotification('a')), 'o-1');
      expect(notificationOrderId(testNotification('b', data: null)), isNull);
      expect(notificationOrderId(testNotification('c', data: const {'x': 1})), isNull);
    });
  });

  group('the screen', () {
    final now = DateTime.now().toUtc();

    Future<(GoRouter, FakeNotificationRepository)> pump(WidgetTester tester, void Function(FakeNotificationRepository) seed) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 844 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final repo = FakeNotificationRepository();
      seed(repo);
      final router = testRouter(
        {
          Routes.home: () => const Text('HOME PAGE'),
          Routes.notifications: () => const NotificationsScreen(),
          Routes.orderDetail: () => const Text('ORDER PAGE'),
          Routes.offers: () => const Text('OFFERS PAGE'),
        },
        initial: Routes.notifications,
      );
      await tester.pumpWidget(themedRouter(router, overrides: [notificationRepositoryProvider.overrideWithValue(repo), sessionProvider.overrideWith(SignedInSession.new)]));
      await tester.pumpAndSettle();
      return (router, repo);
    }

    testWidgets('groups by Today and Earlier, and shows unread ones in bold with a dot', (tester) async {
      await pump(tester, (r) {
        r.inbox.addAll([
          testNotification('n1', title: 'Partner on the way', createdAt: now),
          testNotification('n2', type: 'payment_received', title: 'Payment received', body: '₹248 received for order ID001046.', createdAt: now, readAt: now),
          testNotification('n3', title: 'We have your clothes', createdAt: now.subtract(const Duration(days: 3)), readAt: now),
        ]);
      });

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Earlier'), findsOneWidget);
      expect(find.text('Partner on the way'), findsOneWidget);
      expect(find.text('Payment received'), findsOneWidget);
      expect(find.text('We have your clothes'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
    });

    testWidgets('tapping one marks it read and opens its order', (tester) async {
      final (router, repo) = await pump(tester, (r) => r.inbox.add(testNotification('n1', createdAt: now)));
      await tester.tap(find.text('Partner on the way'));
      await tester.pumpAndSettle();
      expect(repo.markedRead, ['n1']);
      expect(router.state.matchedLocation, Routes.order('o-1'));
    });

    testWidgets('an offer opens the Offers tab', (tester) async {
      final (router, _) = await pump(tester, (r) => r.inbox.add(testNotification('n1', type: 'offer', title: '20% off', data: null, createdAt: now)));
      await tester.tap(find.text('20% off'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.offers);
    });

    testWidgets('Mark all read clears the button and the dots', (tester) async {
      final (_, repo) = await pump(tester, (r) => r.inbox.addAll([testNotification('n1', createdAt: now), testNotification('n2', createdAt: now)]));
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();
      expect(repo.markedAll, 1);
      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets('an empty inbox says everything is caught up', (tester) async {
      await pump(tester, (_) {});
      expect(find.text("You're all caught up"), findsOneWidget);
      expect(find.text('Updates on your orders and payments will appear here.'), findsOneWidget);
      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets('a failure to load can be retried', (tester) async {
      final (_, repo) = await pump(tester, (r) => r.listFailure = const ApiFailure(ApiFailureKind.offline));
      expect(find.text("Couldn't load notifications"), findsOneWidget);
      repo
        ..listFailure = null
        ..inbox.add(testNotification('n1', createdAt: now));
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Partner on the way'), findsOneWidget);
    });
  });

  group('times', () {
    test('today as a clock, this week with the day, older as a date', () {
      final now = DateTime.utc(2026, 10, 3, 14, 0); // Sat 7:30 PM IST
      expect(notificationTime(DateTime.utc(2026, 10, 3, 10, 22), now: now), '3:52 PM');
      expect(notificationTime(DateTime.utc(2026, 10, 1, 12, 11), now: now), 'Thu, 5:41 PM');
      expect(notificationTime(DateTime.utc(2026, 9, 26, 6, 0), now: now), '26 Sep');
    });
  });
}
