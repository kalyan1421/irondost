import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/features/basket/basket.dart';
import 'package:irondost_customer/features/catalogue/catalogue.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

void main() {
  Future<ProviderContainer> open({Map<String, Object> saved = const {}, bool loaded = true}) async {
    final container = ProviderContainer(overrides: await basketOverrides(saved: saved));
    addTearDown(container.dispose);
    if (loaded) await container.read(catalogProvider.future);
    container.read(basketProvider);
    return container;
  }

  test('adds, steps down and removes the last piece', () async {
    final c = await open();
    final basket = c.read(basketProvider.notifier);

    expect(basket.add('shirt'), AddResult.added);
    basket.add('shirt');
    basket.add('saree');
    expect(c.read(basketProvider).lines, {'shirt': 2, 'saree': 1});
    expect(c.read(basketCountProvider), 3);

    basket.remove('shirt');
    expect(c.read(basketProvider).quantityOf('shirt'), 1);
    basket.remove('shirt');
    expect(c.read(basketProvider).lines.containsKey('shirt'), isFalse);
    basket.remove('shirt'); // already gone: nothing happens
    expect(c.read(basketProvider).count, 1);
  });

  test('stops at the API limits: 500 of one item, 50 different items', () async {
    final c = await open(saved: {
      'basket.v1': '{"lines":{"shirt":500},"promoCode":null}',
    });
    final basket = c.read(basketProvider.notifier);
    expect(basket.add('shirt'), AddResult.itemLimit);
    expect(c.read(basketProvider).quantityOf('shirt'), 500);

    // Fifty distinct lines straight into storage; the price list hasn't loaded, so nothing is pruned.
    final full = {for (var i = 0; i < 50; i++) 'x$i': 1};
    final c2 = await open(saved: {'basket.v1': Basket(lines: full).encode()}, loaded: false);
    expect(c2.read(basketProvider.notifier).add('shirt'), AddResult.basketFull);
    expect(c2.read(basketProvider.notifier).add('x7'), AddResult.added, reason: 'more of an item already in the basket is fine');
  });

  test('saves every change and restores it on the next launch', () async {
    final c = await open();
    c.read(basketProvider.notifier)
      ..add('shirt')
      ..add('shirt')
      ..add('saree')
      ..applyPromo('  welcome20 ');
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('basket.v1')!;

    final next = await open(saved: {'basket.v1': raw});
    expect(next.read(basketProvider).lines, {'shirt': 2, 'saree': 1});
    expect(next.read(basketProvider).promoCode, 'WELCOME20');
  });

  test('an emptied basket forgets its promo code and its saved copy', () async {
    final c = await open();
    final basket = c.read(basketProvider.notifier)
      ..add('shirt')
      ..applyPromo('WELCOME20')
      ..remove('shirt');
    expect(c.read(basketProvider).promoCode, isNull);
    expect((await SharedPreferences.getInstance()).containsKey('basket.v1'), isFalse);
    expect(basket.add('saree'), AddResult.added);
    expect(c.read(basketProvider).promoCode, isNull);
  });

  test('damaged saved data is an empty basket, not a crash', () async {
    for (final bad in ['not json', '{"lines":"x"}', '{"lines":{"shirt":-3,"saree":"2","kurta":9999}}']) {
      final c = await open(saved: {'basket.v1': bad});
      expect(c.read(basketProvider).isEmpty, isTrue, reason: bad);
    }
  });

  test('items the admin hid since are dropped once the price list is known', () async {
    final c = await open(saved: {
      'basket.v1': '{"lines":{"shirt":2,"retired":4},"promoCode":null}',
    });
    expect(c.read(basketProvider).lines, {'shirt': 2});
  });

  test('keeps the saved basket while the price list has not loaded yet, then prunes', () async {
    final c = await open(saved: {
      'basket.v1': '{"lines":{"shirt":2,"retired":4},"promoCode":null}',
    }, loaded: false);
    expect(c.read(basketProvider).lines.keys, containsAll(['shirt', 'retired']));
    await c.read(catalogProvider.future);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(basketProvider).lines, {'shirt': 2});
  });

  test('estimates the items total from the price list, using offer prices', () async {
    final catalog = [
      testCategory('ironing', 'Ironing', [testItem('shirt', 'Shirt', 1500, offerPaise: 1200), testItem('saree', 'Saree', 5000)]),
    ];
    final container = ProviderContainer(overrides: await basketOverrides(catalog: catalog));
    addTearDown(container.dispose);
    await container.read(catalogProvider.future);
    container.read(basketProvider.notifier)
      ..add('shirt')
      ..add('shirt')
      ..add('saree');
    expect(container.read(basketEstimateProvider), 2 * 1200 + 5000);
  });

  test('bookable() keeps active categories with active items, in the admin order', () {
    final all = [
      testCategory('b', 'B', [testItem('b2', 'B2', 100, sortOrder: 2), testItem('b1', 'B1', 100, sortOrder: 1), testItem('b0', 'Off', 100, isActive: false)], sortOrder: 2),
      testCategory('a', 'A', [testItem('a1', 'A1', 100)], sortOrder: 1),
      testCategory('hidden', 'Hidden', [testItem('h1', 'H1', 100)], sortOrder: 0, isActive: false),
      testCategory('empty', 'Empty', [testItem('e1', 'E1', 100, isActive: false)], sortOrder: 3),
    ];
    final result = bookable(all);
    expect(result.map((c) => c.slug), ['a', 'b']);
    expect(result[1].items.map((i) => i.id), ['b1', 'b2']);
  });
}
