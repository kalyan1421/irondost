import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/basket/basket.dart';
import 'package:irondost_customer/features/basket/basket_screen.dart';
import 'package:irondost_customer/features/basket/quote.dart';

import '../helpers.dart';

/// Lets the quote's debounce timer fire (it schedules no frame, so pumpAndSettle alone would not), then settles.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(quoteDebounce + const Duration(milliseconds: 10));
  await tester.pumpAndSettle();
}

void main() {
  const tenShirtsAndASaree = '{"lines":{"shirt":10,"trousers":4,"saree":1},"promoCode":null}';

  Future<(ProviderContainer, FakeQuoteRepository)> pump(
    WidgetTester tester, {
    Map<String, Object> saved = const {},
    FakeQuoteRepository? quotes,
    List<PromotionDto> promotions = const [],
  }) async {
    final fake = quotes ?? FakeQuoteRepository();
    await tester.pumpWidget(themed(const BasketScreen(), overrides: await basketOverrides(saved: saved, quotes: fake, promotions: promotions)));
    await settle(tester);
    return (ProviderScope.containerOf(tester.element(find.byType(Scaffold).first)), fake);
  }

  testWidgets('an empty basket says so and offers the catalogue', (tester) async {
    await pump(tester);
    expect(find.text('Your basket is empty'), findsOneWidget);
    expect(find.text('Choose items'), findsOneWidget);
    expect(find.text('Choose pickup time'), findsNothing);
  });

  testWidgets('lists the saved items by service and shows the server bill', (tester) async {
    final (_, quotes) = await pump(tester, saved: {'basket.v1': tenShirtsAndASaree});

    expect(find.text('Ironing'), findsOneWidget);
    expect(find.text('15 items'), findsOneWidget);
    expect(find.text('Shirt / T-shirt'), findsOneWidget);
    expect(find.text('₹15 each'), findsNWidgets(2));
    expect(find.text('₹150'), findsOneWidget, reason: 'ten shirts');
    await tester.scrollUntilVisible(find.text('To pay'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Items (15)'), findsOneWidget);
    expect(find.text('₹260'), findsNWidgets(3), reason: 'items, to pay, and the total in the footer');
    expect(find.text('Total'), findsOneWidget, reason: 'the footer keeps the amount in view even when the bill is scrolled away');
    expect(find.text('Free'), findsOneWidget);
    expect(find.text('To pay'), findsOneWidget);
    expect(quotes.calls, hasLength(1));
    expect(quotes.calls.single.$2, isNull);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Choose pickup time')).onPressed, isNotNull);
  });

  testWidgets('each line price sits at the right edge of its row, not mid-screen', (tester) async {
    await pump(tester, saved: {'basket.v1': tenShirtsAndASaree});
    final screen = tester.getSize(find.byType(Scaffold).first).width;

    // Ten shirts at ₹15. The price must end where the content ends (20 dp gutter), whatever the name's length.
    final priceRight = tester.getTopRight(find.text('₹150')).dx;
    expect(priceRight, closeTo(screen - 20, 1));
    expect(tester.getTopLeft(find.text('₹150')).dx, greaterThan(screen / 2), reason: 'a short price must not start at the row midpoint');
  });

  testWidgets('a burst of taps is priced once, after the pause', (tester) async {
    final (container, quotes) = await pump(tester, saved: {'basket.v1': tenShirtsAndASaree});
    quotes.calls.clear();

    await tester.ensureVisible(find.bySemanticsLabel('Add one Saree'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Add one Saree'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.ensureVisible(find.bySemanticsLabel('Add one Saree'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Add one Saree'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.ensureVisible(find.bySemanticsLabel('Add one Saree'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Add one Saree'));
    expect(quotes.calls, isEmpty, reason: 'still inside the debounce');
    await settle(tester);

    expect(quotes.calls, hasLength(1));
    expect(container.read(basketProvider).quantityOf('saree'), 4);
    await tester.scrollUntilVisible(find.text('To pay'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('₹410'), findsNWidgets(3), reason: 'items, to pay, and the footer total');
  });

  testWidgets('the Choose pickup time button waits for the new price', (tester) async {
    await pump(tester, saved: {'basket.v1': tenShirtsAndASaree});
    await tester.ensureVisible(find.bySemanticsLabel('Add one Saree'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Add one Saree'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Choose pickup time')).onPressed, isNull);
    await settle(tester);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Choose pickup time')).onPressed, isNotNull);
  });

  testWidgets('taking out the last piece removes the row, and Undo puts it back', (tester) async {
    final (container, _) = await pump(tester, saved: {'basket.v1': '{"lines":{"shirt":2,"saree":1},"promoCode":null}'});

    await tester.tap(find.bySemanticsLabel('Remove one Saree'));
    await settle(tester);
    expect(find.text('Saree'), findsNothing);
    expect(find.text('Removed Saree'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(container.read(basketProvider).quantityOf('saree'), 1);
    expect(find.text('Saree'), findsOneWidget);
  });

  testWidgets('removing everything shows the empty basket', (tester) async {
    await pump(tester, saved: {'basket.v1': '{"lines":{"saree":1},"promoCode":null}'});
    await tester.tap(find.bySemanticsLabel('Remove one Saree'));
    await settle(tester);
    expect(find.text('Your basket is empty'), findsOneWidget);
  });

  testWidgets('below the minimum order it asks for the difference instead of offering pickup', (tester) async {
    final quotes = FakeQuoteRepository()..minOrderPaise = 19900;
    await pump(tester, saved: {'basket.v1': '{"lines":{"shirt":6,"saree":1},"promoCode":null}'}, quotes: quotes);

    expect(find.textContaining('more to book. The minimum order is ₹199.'), findsOneWidget);
    expect(find.text('Add ₹59 more'), findsOneWidget);
    expect(find.text('Choose pickup time'), findsNothing);
  });

  testWidgets('when the total cannot be worked out it says so and Try again recovers', (tester) async {
    final quotes = FakeQuoteRepository()..failure = const ApiFailure(ApiFailureKind.offline);
    await pump(tester, saved: {'basket.v1': tenShirtsAndASaree}, quotes: quotes);

    await tester.scrollUntilVisible(find.text('Try again'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.textContaining("Couldn't work out the total"), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Choose pickup time')).onPressed, isNull);

    quotes.failure = null;
    await tester.tap(find.text('Try again'));
    await settle(tester);
    expect(find.text('To pay'), findsOneWidget);
    expect(find.textContaining("Couldn't work out"), findsNothing);
  });

  group('promo codes', () {
    testWidgets('a valid code is checked, applied, and shown in the bill', (tester) async {
      final (container, quotes) = await pump(tester, saved: {'basket.v1': tenShirtsAndASaree});

      await tester.scrollUntilVisible(find.text('Apply a promo code'), 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply a promo code'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'welcome20');
      await tester.tap(find.text('Apply').first);
      await settle(tester);

      expect(find.text('Apply a code'), findsNothing, reason: 'sheet closed');
      expect(container.read(basketProvider).promoCode, 'WELCOME20');
      expect(quotes.calls.last.$2, 'WELCOME20');
      expect(find.textContaining('applied. You save ₹52.'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('To pay'), 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text('−₹52'), findsOneWidget);
      expect(find.text('₹208'), findsNWidgets(2), reason: 'to pay, and the footer total');
    });

    testWidgets('an unknown, expired or used code is explained under the field and not applied', (tester) async {
      final (container, _) = await pump(tester, saved: {'basket.v1': tenShirtsAndASaree});
      await tester.scrollUntilVisible(find.text('Apply a promo code'), 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply a promo code'));
      await settle(tester);

      for (final (code, message) in [
        ('NOPE', "We couldn't find that code. Check the spelling."),
        ('EXPIRED', 'This code has expired.'),
        ('USEDUP', "You've already used this code."),
        ('BIG', 'Add ₹240 more to use this code.'),
      ]) {
        await tester.enterText(find.byType(TextField), code);
        await tester.tap(find.text('Apply').first);
        await settle(tester);
        expect(find.text(message), findsOneWidget, reason: code);
      }
      expect(container.read(basketProvider).promoCode, isNull);
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Apply').first);
      await settle(tester);
      expect(find.text('Enter a code.'), findsOneWidget);
    });

    testWidgets('offers running now are listed; one below its minimum is disabled and says how much more', (tester) async {
      await pump(
        tester,
        saved: {'basket.v1': tenShirtsAndASaree},
        promotions: [testPromo('WELCOME20', '20% off your first order', minOrderPaise: 10000, maxDiscountPaise: 10000), testPromo('BIG', '10% off orders above ₹500', minOrderPaise: 50000)],
      );
      await tester.scrollUntilVisible(find.text('Apply a promo code'), 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply a promo code'));
      await settle(tester);

      expect(find.text('Available for you'), findsOneWidget);
      expect(find.text('Up to ₹100 · Min. order ₹100'), findsOneWidget);
      expect(find.text('Add ₹240 more to use this'), findsOneWidget);
      final applyButtons = find.widgetWithText(FilledButton, 'Apply');
      expect(tester.widget<FilledButton>(applyButtons.at(0)).onPressed, isNotNull);
      expect(tester.widget<FilledButton>(applyButtons.at(1)).onPressed, isNull);
    });

    testWidgets('a saved code that has since expired shows why, blocks pickup, and can be removed', (tester) async {
      final (container, _) = await pump(tester, saved: {'basket.v1': '{"lines":{"shirt":6,"saree":1},"promoCode":"EXPIRED"}'});

      expect(find.text('EXPIRED'), findsOneWidget);
      expect(find.text('This code has expired.'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Choose pickup time')).onPressed, isNull);

      await tester.tap(find.text('Change'));
      await settle(tester);
      await tester.tap(find.text('Remove EXPIRED'));
      await settle(tester);
      expect(container.read(basketProvider).promoCode, isNull);
      expect(find.text('Apply a promo code'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Choose pickup time')).onPressed, isNotNull);
    });
  });
}
