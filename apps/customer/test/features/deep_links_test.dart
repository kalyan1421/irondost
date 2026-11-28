import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/links.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/features/analytics/analytics.dart';
import 'package:irondost_customer/features/shell/open_target.dart';
import 'package:irondost_customer/features/support/support.dart';

import '../helpers.dart';

class FakeLinks implements LinkSource {
  Uri? first;
  final controller = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> initial() async => first;

  @override
  Stream<Uri> get stream => controller.stream;
}

void main() {
  group('resolving links', () {
    AppLink? app(String raw) => resolveLink(raw) as AppLink?;

    test('the website paths the app opens', () {
      expect(app('https://irondost.in/get?src=ig&c=diwali'), const AppLink(Routes.home, src: 'ig', campaign: 'diwali'));
      expect(app('https://www.irondost.in/offers')!.route, Routes.offers);
      expect(app('https://irondost.in/o/ord_123')!.route, Routes.order('ord_123'));
      expect(app('https://irondost.in/r/ravi50'), const AppLink(Routes.home, referralCode: 'ravi50'));
    });

    test('in-app paths a campaign can point at', () {
      expect(app('/offers')!.route, Routes.offers);
      expect(app('/orders/o-9')!.route, Routes.order('o-9'));
      expect(app('/orders')!.route, Routes.orders);
      expect(app('/catalogue')!.route, Routes.book);
      expect(app('/catalogue?service=dry-cleaning')!.route, '${Routes.book}?service=dry-cleaning');
      expect(app('/basket')!.route, Routes.basket);
      expect(app('/notifications')!.route, Routes.notifications);
    });

    test('other https pages open in the browser; anything else goes nowhere', () {
      expect(resolveLink('https://instagram.com/irondost'), WebLink(Uri.parse('https://instagram.com/irondost')));
      expect(resolveLink('https://irondost.in/blog/how-we-iron'), WebLink(Uri.parse('https://irondost.in/blog/how-we-iron')));
      expect(resolveLink('http://example.com'), isNull);
      expect(resolveLink('javascript:alert(1)'), isNull);
      expect(resolveLink('/no-such-screen'), isNull);
      expect(resolveLink('  '), isNull);
      expect(resolveLink(null), isNull);
    });

    test('tabs are told apart from screens that open on top', () {
      expect(isTabRoute(Routes.home), isTrue);
      expect(isTabRoute(Routes.basket), isTrue);
      expect(isTabRoute(Routes.offers), isFalse);
      expect(isTabRoute(Routes.order('o-1')), isFalse);
    });
  });

  group('incoming website links', () {
    Future<(ProviderContainer, FakeLinks, RecordingAnalytics)> start({Uri? initial}) async {
      final links = FakeLinks()..first = initial;
      final analytics = RecordingAnalytics();
      final c = ProviderContainer(
        overrides: [
          ...await basketOverrides(),
          linkSourceProvider.overrideWithValue(links),
          analyticsSinkProvider.overrideWithValue(analytics),
        ],
      );
      addTearDown(c.dispose);
      c.read(deepLinkListenerProvider);
      await pumpEventQueue();
      return (c, links, analytics);
    }

    test('the link that started the app waits for the tabs, keeping its source and campaign', () async {
      final (c, _, analytics) = await start(initial: Uri.parse('https://irondost.in/get?src=ig&c=diwali'));
      expect(c.read(pendingLinkProvider), Routes.home);
      expect(analytics.properties, {'src': 'ig', 'c': 'diwali'});
    });

    test('a referral link keeps its code for checkout', () async {
      final (c, links, _) = await start();
      links.controller.add(Uri.parse('https://irondost.in/r/ravi50'));
      await pumpEventQueue();
      expect(c.read(referralCodeProvider), 'RAVI50');
      expect(c.read(pendingLinkProvider), Routes.home);
    });

    test('the launch link coming down the stream as well is opened once', () async {
      final (c, links, _) = await start(initial: Uri.parse('https://irondost.in/o/o-7'));
      expect(c.read(pendingLinkProvider), Routes.order('o-7'));
      c.read(pendingLinkProvider.notifier).done();
      links.controller.add(Uri.parse('https://irondost.in/o/o-7'));
      await pumpEventQueue();
      expect(c.read(pendingLinkProvider), isNull);
    });

    test('an order link opens that order', () async {
      final (c, links, _) = await start();
      links.controller.add(Uri.parse('https://irondost.in/o/o-7'));
      await pumpEventQueue();
      expect(c.read(pendingLinkProvider), Routes.order('o-7'));
    });

    test('URLs that are not irondost.in (the phone-check callback, Google sign-in) are left alone', () async {
      final (c, links, _) = await start();
      links.controller
        ..add(Uri.parse('app-1-264618787416-ios-cb0f4ba0c34909cec7c02d://firebaseauth/link?deep_link_id=x'))
        ..add(Uri.parse('https://irondost.in/blog/post'));
      await pumpEventQueue();
      expect(c.read(pendingLinkProvider), isNull);
    });
  });

  group('opening a target', () {
    late List<Uri> launched;

    Future<GoRouter> pump(WidgetTester tester, String target) async {
      launched = [];
      final router = testRouter({
        Routes.home: () => Consumer(
              builder: (context, ref, _) => TextButton(onPressed: () => openTarget(context, ref, target), child: const Text('GO')),
            ),
        Routes.offers: () => const Text('OFFERS PAGE'),
        Routes.basket: () => const Text('BASKET PAGE'),
      }, initial: Routes.home);
      await tester.pumpWidget(themedRouter(router, overrides: [
        supportLauncherProvider.overrideWithValue((uri) async {
          launched.add(uri);
          return true;
        }),
      ]));
      await tester.tap(find.text('GO'));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('a screen opens on top, so Back returns', (tester) async {
      final router = await pump(tester, Routes.offers);
      expect(find.text('OFFERS PAGE'), findsOneWidget);
      expect(router.canPop(), isTrue);
    });

    testWidgets('a tab is switched to', (tester) async {
      final router = await pump(tester, Routes.basket);
      expect(find.text('BASKET PAGE'), findsOneWidget);
      expect(router.canPop(), isFalse);
    });

    testWidgets('a web page goes to the browser', (tester) async {
      await pump(tester, 'https://instagram.com/irondost');
      expect(launched, [Uri.parse('https://instagram.com/irondost')]);
      expect(find.text('GO'), findsOneWidget);
    });
  });
}
