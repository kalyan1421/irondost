import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/offers/offers_screen.dart';
import 'package:irondost_customer/features/offers/promotions.dart';

import '../helpers.dart';

void main() {
  final welcome = testPromo(
    'WELCOME20',
    '20% off your first order',
    minOrderPaise: 29900,
    maxDiscountPaise: 10000,
    limit: 1,
  );
  final fresh = testPromo(
    'FRESH15',
    '15% off orders above ₹500',
    value: 15,
    minOrderPaise: 50000,
    maxDiscountPaise: 15000,
  );
  final flat = testPromo(
    'FLAT50',
    '₹50 off orders above ₹400',
    type: DiscountType.flat,
    value: 5000,
    minOrderPaise: 40000,
    limit: 2,
    description: 'On any service.',
  );

  group('what an offer says', () {
    test('terms list the cap, minimum, limit and last day', () {
      expect(promoTerms(welcome), 'Up to ₹100 · Min. order ₹299');
      expect(
        promoTerms(welcome, withLimit: true),
        'Up to ₹100 · Min. order ₹299 · Once per customer',
      );
      expect(
        promoTerms(flat, withLimit: true, withValidity: true),
        'Min. order ₹400 · Twice per customer · Valid till 31 Dec',
      );
      expect(
        promoTerms(testPromo('X', 'x', limit: 5), withLimit: true),
        '5 times per customer',
      );
      expect(promoTerms(testPromo('FREE', 'x')), '');
    });

    test('the badge reads as a percentage or rupees off', () {
      expect(promoBadge(welcome), '20% off');
      expect(promoBadge(testPromo('H', 'x', value: 12.5)), '12.5% off');
      expect(promoBadge(flat), '₹50 off');
    });
  });

  group('the offers tab', () {
    Future<void> open(
      WidgetTester tester, {
      required Future<List<PromotionDto>> Function() promotions,
    }) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 844 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        themed(
          const OffersScreen(),
          overrides: [promotionsProvider.overrideWith((ref) => promotions())],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'offers use clear discount badges and complete eligibility terms',
      (tester) async {
        await open(tester, promotions: () async => [welcome, fresh, flat]);

        expect(find.text('20% off'), findsOneWidget);
        expect(find.text('20% off your first order'), findsOneWidget);
        expect(
          find.text(
            'Up to ₹100 · Min. order ₹299 · Once per customer · Valid till 31 Dec',
          ),
          findsOneWidget,
        );
        expect(find.text('15% off'), findsOneWidget);
        expect(find.text('₹50 off'), findsOneWidget);
        expect(find.text('On any service.'), findsOneWidget);
        expect(find.text('WELCOME20'), findsOneWidget);
        expect(find.text('FRESH15'), findsOneWidget);
        await tester.ensureVisible(find.text('FRESH15'));
        await tester.pumpAndSettle();
        expect(find.text('FRESH15'), findsOneWidget);
      },
    );

    testWidgets(
      'a featured offer that is not a welcome offer shows its discount',
      (tester) async {
        await open(tester, promotions: () async => [fresh]);
        expect(find.text('15% off'), findsOneWidget);
        expect(find.text('New here'), findsNothing);
      },
    );

    testWidgets('copying a code copies it and says where to use it', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await open(tester, promotions: () async => [welcome, fresh]);

      await tester.tap(find.text('WELCOME20'));
      await tester.pump();
      expect(copied, 'WELCOME20');
      expect(
        find.text('Code WELCOME20 copied. Apply it in your basket.'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('FRESH15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FRESH15'));
      await tester.pumpAndSettle();
      expect(copied, 'FRESH15');
      expect(
        find.text('Code FRESH15 copied. Apply it in your basket.'),
        findsOneWidget,
      );
    });

    testWidgets('no offers says so kindly', (tester) async {
      await open(tester, promotions: () async => []);
      expect(find.text('No offers right now'), findsOneWidget);
      expect(
        find.textContaining('Available offers will appear here'),
        findsOneWidget,
      );
    });

    testWidgets('offline offers a retry that loads them', (tester) async {
      var online = false;
      await open(
        tester,
        promotions: () async {
          if (!online) throw const ApiFailure(ApiFailureKind.offline);
          return [welcome];
        },
      );
      expect(find.text('Couldn’t load offers'), findsOneWidget);
      expect(find.textContaining('Check your connection'), findsOneWidget);

      online = true;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('20% off your first order'), findsOneWidget);
    });

    testWidgets('a server error is not blamed on the connection', (
      tester,
    ) async {
      await open(
        tester,
        promotions: () async => throw const ApiFailure(ApiFailureKind.server),
      );
      expect(find.text('Couldn’t load offers'), findsOneWidget);
      expect(find.textContaining('Check your connection'), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
