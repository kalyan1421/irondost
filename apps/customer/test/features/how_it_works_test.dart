import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/account/help_screen.dart';
import 'package:irondost_customer/features/account/legal_content.dart';
import 'package:irondost_customer/features/addresses/address_repository.dart';
import 'package:irondost_customer/features/home/home_screen.dart';
import 'package:irondost_customer/features/home/how_it_works.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/startup/startup.dart';

import '../helpers.dart';

PublicConfigDto _config({int hours = 20}) => PublicConfigDto(
  appName: 'IronDost',
  supportPhone: '+919063290012',
  supportEmail: null,
  minOrderPaise: 0,
  deliveryFeePaise: 0,
  freeDeliveryAbovePaise: null,
  minTurnaroundHours: hours,
  maxAdvanceDays: 30,
  slots: const [],
);

/// Everything a policy says, as one string.
String _text(LegalDoc doc) => [
  for (final s in doc.page.sections) ...[...s.paragraphs, ...s.bullets],
].join(' ');

void main() {
  void phone(WidgetTester tester, {double height = 1800}) {
    tester.view
      ..physicalSize = Size(390 * 2, height * 2)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  test(
    'every sentence the sheet restates is still in the policy it comes from',
    () {
      // If a policy is reworded, this fails: the sheet must be read again against the new wording,
      // not left promising what the Terms no longer say.
      for (final (doc, phrase) in howItWorksSources) {
        expect(
          _text(doc),
          contains(phrase),
          reason: '"$phrase" is no longer in ${doc.slug}',
        );
      }
    },
  );

  group('opened from Home', () {
    Future<GoRouter> openHome(
      WidgetTester tester, {
      int hours = 20,
      double textScale = 1,
    }) async {
      final router = testRouter({
        Routes.home: () => const HomeScreen(),
        Routes.legalDoc: () => const Text('LEGAL PAGE'),
      }, initial: Routes.home);
      await tester.pumpWidget(
        themedRouter(
          router,
          textScale: textScale,
          overrides: [
            ...await basketOverrides(),
            addressRepositoryProvider.overrideWithValue(
              FakeAddressRepository([testAddress()]),
            ),
            orderRepositoryProvider.overrideWithValue(FakeOrderRepository()),
            startupProvider.overrideWith(
              (ref) async => Startup(
                config: _config(hours: hours),
                installedVersion: '2.0.0',
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      // In the app the config is loaded before Home is shown; in a test it loads on first read, so
      // wait for it, or the sheet would quietly use its fallback.
      await ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      ).read(startupProvider.future);
      return router;
    }

    testWidgets('says what happens, in the same words as the policies', (
      tester,
    ) async {
      phone(tester);
      await openHome(tester);

      await tester.tap(find.text('How it works'));
      await tester.pumpAndSettle();

      expect(find.text('Pickup and count'), findsOneWidget);
      expect(
        find.text(
          'Your partner collects your clothes and counts them. The bill follows that count.',
        ),
        findsOneWidget,
      );
      expect(find.text('We do the work'), findsOneWidget);
      expect(
        find.text('We iron, wash or dry-clean them as you chose.'),
        findsOneWidget,
      );
      expect(find.text('Back to you'), findsOneWidget);
      expect(
        find.textContaining(
          'Delivery takes about 20 hours or more from pickup',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('The window is our target, not a guarantee.'),
        findsOneWidget,
      );
      expect(find.text('Looking after your clothes'), findsOneWidget);
      expect(
        find.textContaining('within 48 hours of delivery'),
        findsOneWidget,
      );
      expect(find.text('Changing your mind'), findsOneWidget);
      expect(
        find.text('Before pickup: cancel free in the app.'),
        findsOneWidget,
      );
      expect(
        find.text(
          "Once ironing has started, the order can't be cancelled or refunded.",
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'makes no claim about how clothes are ironed, or any guarantee of quality',
      (tester) async {
        phone(tester);
        await openHome(tester);
        await tester.tap(find.text('How it works'));
        await tester.pumpAndSettle();

        // Nothing the policies do not say: no process, no guarantee, no promise of a time.
        for (final word in [
          'steam',
          'press',
          'guarantee ',
          'satisfaction',
          'free delivery',
          'on time',
        ]) {
          expect(
            find.textContaining(word, findRichText: true),
            findsNothing,
            reason: word,
          );
        }
        // "not a guarantee" is the one place the word appears, and it is the policy's own.
        expect(find.textContaining('not a guarantee'), findsOneWidget);
      },
    );

    testWidgets('the turnaround follows the setting the schedule uses', (
      tester,
    ) async {
      phone(tester);
      await openHome(tester, hours: 24);
      await tester.tap(find.text('How it works'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Delivery takes about 24 hours or more'),
        findsOneWidget,
      );
      expect(find.textContaining('about 20 hours'), findsNothing);
    });

    testWidgets('a policy link closes the sheet and opens that policy', (
      tester,
    ) async {
      phone(tester);
      final router = await openHome(tester);
      await tester.tap(find.text('How it works'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terms of service'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/legal/terms');
      expect(find.text('LEGAL PAGE'), findsOneWidget);
      expect(
        find.text('Pickup and count'),
        findsNothing,
        reason: 'the sheet is closed',
      );
    });

    testWidgets('stays readable and reachable at 320 dp and 200% text', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(320 * 2, 740 * 2)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await openHome(tester, textScale: 2);
      // ensureVisible, not scrollUntilVisible: that stops with one edge on screen, and a tap there misses.
      await tester.ensureVisible(find.text('How it works'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('How it works'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'no overflow');
      // The sheet scrolls; everything, down to the last link, can be reached.
      await tester.scrollUntilVisible(
        find.text('Terms of service'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final link = find
          .ancestor(
            of: find.text('Terms of service'),
            matching: find.byType(InkWell),
          )
          .first;
      expect(tester.getSize(link).height, greaterThanOrEqualTo(48));
      expect(tester.getRect(link).right, lessThanOrEqualTo(320));
    });
  });

  testWidgets('Help lists it, and it opens the same sheet', (tester) async {
    phone(tester, height: 1400);
    final router = testRouter({
      Routes.help: () => const HelpScreen(),
    }, initial: Routes.help);
    await tester.pumpWidget(
      themedRouter(
        router,
        overrides: [
          startupProvider.overrideWith(
            (ref) async =>
                Startup(config: _config(), installedVersion: '2.0.0'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('How it works'));
    await tester.pumpAndSettle();

    expect(find.text('Pickup and count'), findsOneWidget);
    expect(find.text('Looking after your clothes'), findsOneWidget);
  });
}
