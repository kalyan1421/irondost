import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';
import 'catalogue.dart';

/// Laundry is IronDost's main service: the category that washes clothes (a slug or name with "laundry" or "wash",
/// never dry cleaning). Booking opens on it and Home leads with it.
bool isLaundry(CatalogCategoryDto category) {
  final s = '${category.slug} ${category.name}'.toLowerCase();
  return !mentionsDryCleaning(s) && (s.contains('laundry') || s.contains('wash'));
}

/// Whether [text] names dry cleaning. "Laundry" contains the letters "dry", so a bare `contains('dry')` is wrong.
bool mentionsDryCleaning(String text) =>
    RegExp(r'(^|[^a-z])dry([\s_-]?clean|$|[^a-z])').hasMatch(text.toLowerCase());

/// The first laundry category in the price list, or null while it loads or when there is none.
CatalogCategoryDto? laundryCategoryOf(List<CatalogCategoryDto> categories) {
  for (final c in categories) {
    if (isLaundry(c)) return c;
  }
  return null;
}

/// The laundry category's slug, for opening the price list on it.
final laundrySlugProvider = Provider<String?>(
  (ref) => laundryCategoryOf(
    ref.watch(servicesProvider).value ?? const <CatalogCategoryDto>[],
  )?.slug,
);
