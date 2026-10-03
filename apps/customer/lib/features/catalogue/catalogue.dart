import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';

/// The price list as the API serves it: categories with their items.
final catalogProvider = FutureProvider<List<CatalogCategoryDto>>((ref) => ref.watch(apiProvider).catalog.catalogControllerList());

/// What the customer can book, in display order: active categories holding at least one active item.
final servicesProvider = Provider<AsyncValue<List<CatalogCategoryDto>>>((ref) => ref.watch(catalogProvider).whenData(bookable));

/// Every bookable item by id, for pricing basket lines. Empty until the price list loads.
final catalogItemsProvider = Provider<Map<String, CatalogItemDto>>((ref) {
  final services = ref.watch(servicesProvider).value ?? const <CatalogCategoryDto>[];
  return {
    for (final category in services)
      for (final item in category.items) item.id: item,
  };
});

/// Active categories with their active items, both sorted by the admin's order.
List<CatalogCategoryDto> bookable(List<CatalogCategoryDto> all) {
  final categories = <CatalogCategoryDto>[];
  for (final c in all.where((c) => c.isActive)) {
    final items = c.items.where((i) => i.isActive).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (items.isEmpty) continue;
    categories.add(
      CatalogCategoryDto(id: c.id, name: c.name, slug: c.slug, imageUrl: c.imageUrl, sortOrder: c.sortOrder, isActive: c.isActive, items: items),
    );
  }
  return categories..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}

/// "per piece", "per pair", "per set", "per kg".
String unitLabel(ItemUnit unit) => switch (unit) {
      ItemUnit.piece => 'per piece',
      ItemUnit.pair => 'per pair',
      ItemUnit.valueSet => 'per set',
      ItemUnit.kg => 'per kg',
      ItemUnit.$unknown => 'each',
    };
