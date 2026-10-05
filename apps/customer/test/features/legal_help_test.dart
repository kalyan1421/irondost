import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/account/help_screen.dart';
import 'package:irondost_customer/features/account/legal_content.dart';
import 'package:irondost_customer/features/account/legal_screen.dart';
import 'package:irondost_customer/features/startup/startup.dart';

import '../helpers.dart';

PublicConfigDto _config({
  int hours = 20,
  String? email = 'help@irondost.test',
}) => PublicConfigDto(
  appName: 'IronDost',
  supportPhone: '+919063290012',
  supportEmail: email,
  minOrderPaise: 0,
  deliveryFeePaise: 0,
  freeDeliveryAbovePaise: null,
  minTurnaroundHours: hours,
  maxAdvanceDays: 30,
  slots: const [],
);

void main() {
  void phone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  group('policies', () {
    test('every policy has a slug that finds it, and a page of real text', () {
      for (final doc in LegalDoc.values) {
        expect(LegalDoc.fromSlug(doc.slug), doc);
        expect(doc.page.title, isNotEmpty);
        expect(doc.page.sections, isNotEmpty);
        for (final s in doc.page.sections) {
          expect(s.heading, isNotEmpty);
          expect(
            s.paragraphs.length + s.bullets.length,
            greaterThan(0),
            reason: '${doc.slug}: ${s.heading}',
          );
        }
      }
      expect(LegalDoc.fromSlug('nope'), isNull);
      expect(LegalDoc.fromSlug(null), isNull);
    });

    testWidgets(
      'each policy opens with its title, who runs IronDost, and its first section',
      (tester) async {
        phone(tester);
        for (final doc in LegalDoc.values) {
          await tester.pumpWidget(themed(LegalScreen(doc: doc)));
          await tester.pump();
          expect(find.text(doc.page.title), findsOneWidget, reason: doc.slug);
          expect(find.text(LegalContent.byline), findsOneWidget);
          expect(find.text(doc.page.sections.first.heading), findsOneWidget);
        }
      },
    );

    testWidgets('section headings are announced as headings', (tester) async {
      phone(tester);
      await tester.pumpWidget(themed(const LegalScreen(doc: LegalDoc.privacy)));
      final heading = LegalDoc.privacy.page.sections.first.heading;
      final semantics = tester.widget<Semantics>(
        find
            .ancestor(of: find.text(heading), matching: find.byType(Semantics))
            .first,
      );
      expect(semantics.properties.header, isTrue);
    });
  });

  group('help and support', () {
    Future<GoRouter> open(
      WidgetTester tester, {
      PublicConfigDto? config,
    }) async {
      phone(tester);
      final router = GoRouter(
        initialLocation: Routes.account,
        routes: [
          GoRoute(
            path: Routes.account,
            builder: (_, _) => const Text('account tab'),
          ),
          GoRoute(path: Routes.help, builder: (_, _) => const HelpScreen()),
          GoRoute(
            path: Routes.legalDoc,
            builder: (_, state) =>
                Text('policy ${state.pathParameters['doc']}'),
          ),
        ],
      );
      await tester.pumpWidget(
        themedRouter(
          router,
          overrides: [
            startupProvider.overrideWith(
              (ref) async => Startup(
                config: config ?? _config(),
                installedVersion: '2.0.0',
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.text('account tab')),
      );
      await container.read(startupProvider.future);
      unawaited(router.push(Routes.help));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('offers calling and emailing, with the real number', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Call us'), findsOneWidget);
      expect(find.text('+91 90632 90012'), findsOneWidget);
      expect(find.text('Email us'), findsOneWidget);
      expect(find.text('help@irondost.test'), findsOneWidget);
    });

    testWidgets('without a support email there is only the phone', (
      tester,
    ) async {
      await open(tester, config: _config(email: null));
      expect(find.text('Call us'), findsOneWidget);
      expect(find.text('Email us'), findsNothing);
    });

    testWidgets(
      'the first question is open, and tapping another opens it too',
      (tester) async {
        await open(tester, config: _config(hours: 24));
        expect(
          find.textContaining('at least 24 hours after pickup'),
          findsOneWidget,
        );
        expect(
          find.textContaining('until your clothes are picked up'),
          findsNothing,
        );

        await tester.tap(find.text('Can I change or cancel a pickup?'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('until your clothes are picked up'),
          findsOneWidget,
        );

        await tester.tap(find.text('Can I change or cancel a pickup?'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('until your clothes are picked up'),
          findsNothing,
        );
      },
    );

    testWidgets('the damage and refund answers give the time limits', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('What if an item is damaged or missing?'));
      await tester.tap(find.text('How do refunds work?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('within 48 hours'), findsOneWidget);
      expect(find.textContaining('7–14 business days'), findsOneWidget);
    });

    testWidgets('the policy rows open each policy', (tester) async {
      final router = await open(tester);
      final rows = {
        'Cancellation and refunds': 'cancellation',
        'Terms of service': 'terms',
        'Privacy policy': 'privacy',
      };
      for (final MapEntry(:key, :value) in rows.entries) {
        await tester.scrollUntilVisible(
          find.text(key),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        // scrollUntilVisible stops with one edge on screen, where a tap can miss; bring the whole row in.
        await tester.ensureVisible(find.text(key));
        await tester.pumpAndSettle();
        await tester.tap(find.text(key));
        await tester.pumpAndSettle();
        expect(find.text('policy $value'), findsOneWidget, reason: key);
        router.pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('back returns to where the customer came from', (tester) async {
      await open(tester);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('account tab'), findsOneWidget);
    });
  });
}
