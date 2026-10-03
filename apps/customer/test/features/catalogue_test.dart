import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/design/widgets/item_stepper.dart';
import 'package:irondost_customer/features/basket/basket.dart';
import 'package:irondost_customer/features/catalogue/catalogue_screen.dart';
import 'package:irondost_customer/features/catalogue/search_screen.dart';

import '../helpers.dart';

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget screen, {
    Map<String, Object> saved = const {},
    Future<List<CatalogCategoryDto>> Function()? load,
  }) async {
    await tester.pumpWidget(themed(screen, overrides: await basketOverrides(saved: saved, load: load)));
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
  }

  testWidgets('shows the first service with prices, and the other services as tabs', (tester) async {
    await pump(tester, const CatalogueScreen());

    expect(find.text('Choose items'), findsOneWidget);
    expect(find.text('Ironing'), findsOneWidget);
    expect(find.text('Wash & iron'), findsOneWidget);
    expect(find.text('Shirt / T-shirt'), findsOneWidget);
    expect(find.text('₹15'), findsNWidgets(2));
    expect(find.text('₹50'), findsOneWidget);
    expect(find.text('per piece'), findsNWidgets(3));
    expect(find.text('Review basket'), findsNothing, reason: 'no cart bar for an empty basket');
  });

  testWidgets('opens on the service Home asked for, and switching tabs shows that service', (tester) async {
    await pump(tester, const CatalogueScreen(service: 'wash-and-iron'));
    expect(find.text('₹35'), findsOneWidget);
    expect(find.text('Saree'), findsNothing);

    await tester.tap(find.text('Ironing'));
    await tester.pumpAndSettle();
    expect(find.text('Saree'), findsOneWidget);
    expect(find.text('₹35'), findsNothing);
  });

  testWidgets('ADD turns into a stepper and the cart bar totals the basket', (tester) async {
    final container = await pump(tester, const CatalogueScreen());

    await tester.tap(find.bySemanticsLabel('Add Shirt / T-shirt'));
    await tester.pump();
    expect(find.text('Review basket'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('₹15'), findsNWidgets(3), reason: 'two rows and the bar total');

    await tester.tap(find.bySemanticsLabel('Add one Shirt / T-shirt'));
    await tester.tap(find.bySemanticsLabel('Add Saree'));
    await tester.pumpAndSettle();
    expect(find.text('3 items'), findsOneWidget);
    expect(find.text('₹80'), findsOneWidget);
    expect(container.read(basketProvider).lines, {'shirt': 2, 'saree': 1});

    await tester.tap(find.bySemanticsLabel('Remove one Saree'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Add Saree'), findsOneWidget, reason: 'back to ADD at zero');
    expect(find.text('2 items'), findsOneWidget);
  });

  testWidgets('a basket saved earlier is shown on the steppers and in the cart bar', (tester) async {
    await pump(tester, const CatalogueScreen(), saved: {'basket.v1': '{"lines":{"shirt":10,"trousers":4},"promoCode":null}'});
    expect(find.text('14 items'), findsOneWidget);
    expect(find.text('₹210'), findsOneWidget);
    expect(find.bySemanticsLabel('Shirt / T-shirt, 10 in basket'), findsOneWidget);
  });

  testWidgets('hitting the per-item limit disables the plus and keeps the count', (tester) async {
    await pump(tester, const CatalogueScreen(), saved: {'basket.v1': '{"lines":{"shirt":500},"promoCode":null}'});
    final plus = tester.widget<Semantics>(find.descendant(of: find.byType(ItemStepper), matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Add one Shirt / T-shirt')));
    expect(plus.properties.enabled, isFalse);
  });

  testWidgets('an unreachable price list shows "Couldn\'t load prices" and Try again recovers', (tester) async {
    var fail = true;
    await pump(
      tester,
      const CatalogueScreen(),
      saved: {'basket.v1': '{"lines":{"shirt":2},"promoCode":null}'},
      load: () async {
        if (fail) throw Exception('offline');
        return testCatalog();
      },
    );
    expect(find.text("Couldn't load prices"), findsOneWidget);
    expect(find.textContaining('Items already in your basket are kept'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load prices"), findsNothing);
    expect(find.text('Saree'), findsOneWidget);
  });

  testWidgets('search filters across services and labels which service each row belongs to', (tester) async {
    await pump(tester, const SearchScreen());
    await tester.enterText(find.byType(TextField), 'shirt');
    await tester.pumpAndSettle();

    expect(find.text('Shirt / T-shirt'), findsNWidgets(2));
    expect(find.text('per piece · Ironing'), findsOneWidget);
    expect(find.text('per piece · Wash & iron'), findsOneWidget);
    expect(find.text('Saree'), findsNothing);
  });

  testWidgets('search with no match explains, offers a call, and a popular item fills the field', (tester) async {
    await pump(tester, const SearchScreen());
    await tester.enterText(find.byType(TextField), 'curtain');
    await tester.pumpAndSettle();

    expect(find.text('No items match "curtain"'), findsOneWidget);
    expect(find.textContaining('Call +91'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'Trousers / Jeans'));
    await tester.pumpAndSettle();
    expect(find.text('No items match "curtain"'), findsNothing);
    expect(find.text('per piece · Ironing'), findsOneWidget);
  });
}
