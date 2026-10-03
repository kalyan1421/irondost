import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api_client.dart';
import '../auth/session.dart';
import '../catalogue/catalogue.dart';

/// Opened once in `main()`, so the basket can be read without waiting.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden with an opened SharedPreferences'),
);

/// What is in the basket: item id → count, and the promo code the customer applied. Saved on the phone.
@immutable
class Basket {
  const Basket({this.lines = const {}, this.promoCode});

  final Map<String, int> lines;
  final String? promoCode;

  bool get isEmpty => lines.isEmpty;

  /// Pieces in total, not distinct items.
  int get count => lines.values.fold(0, (a, b) => a + b);

  int quantityOf(String itemId) => lines[itemId] ?? 0;

  List<OrderLineInput> get items => [for (final e in lines.entries) OrderLineInput(catalogItemId: e.key, quantity: e.value)];

  String encode() => jsonEncode({'lines': lines, 'promoCode': promoCode});

  /// Reads what [encode] wrote. A missing or damaged value is an empty basket.
  factory Basket.decode(String? raw) {
    if (raw == null) return const Basket();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final lines = <String, int>{};
      for (final e in (json['lines'] as Map<String, dynamic>).entries) {
        final qty = e.value;
        if (qty is int && qty > 0 && qty <= BasketController.maxPerItem) lines[e.key] = qty;
      }
      return Basket(lines: lines, promoCode: lines.isEmpty ? null : json['promoCode'] as String?);
    } on Object {
      return const Basket();
    }
  }
}

/// Why [BasketController.add] did not add.
enum AddResult { added, itemLimit, basketFull }

final basketProvider = NotifierProvider<BasketController, Basket>(BasketController.new);

class BasketController extends Notifier<Basket> {
  /// The API's own limits on one order (`POST /v1/orders`).
  static const maxPerItem = 500;
  static const maxLines = 50;

  static const _key = 'basket.v1';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Basket build() {
    // The next customer on a shared phone starts with an empty basket.
    ref.listen(sessionProvider, (_, next) {
      if (next.value is SignedOut) clear();
    });
    // Items the admin has since hidden would make every quote fail: drop them once the price list is known.
    ref.listen(servicesProvider, (_, next) {
      final services = next.value;
      if (services != null) _keepOnly(_idsIn(services));
    });
    final saved = Basket.decode(_prefs.getString(_key));
    final services = ref.read(servicesProvider).value;
    if (services == null) return saved;
    final ids = _idsIn(services);
    return Basket(
      lines: {for (final e in saved.lines.entries.where((e) => ids.contains(e.key))) e.key: e.value},
      promoCode: saved.promoCode,
    );
  }

  static Set<String> _idsIn(List<CatalogCategoryDto> services) => {for (final c in services) for (final i in c.items) i.id};

  void _keepOnly(Set<String> ids) {
    if (state.lines.keys.every(ids.contains)) return;
    _set({for (final e in state.lines.entries.where((e) => ids.contains(e.key))) e.key: e.value});
  }

  AddResult add(String itemId) {
    final current = state.quantityOf(itemId);
    if (current >= maxPerItem) return AddResult.itemLimit;
    if (current == 0 && state.lines.length >= maxLines) return AddResult.basketFull;
    _set({...state.lines, itemId: current + 1});
    return AddResult.added;
  }

  /// One less; the last one takes the item out of the basket.
  void remove(String itemId) {
    final current = state.quantityOf(itemId);
    if (current == 0) return;
    final lines = {...state.lines};
    if (current == 1) {
      lines.remove(itemId);
    } else {
      lines[itemId] = current - 1;
    }
    _set(lines);
  }

  void delete(String itemId) {
    if (!state.lines.containsKey(itemId)) return;
    _set({...state.lines}..remove(itemId));
  }

  /// Applies [code] (trimmed, upper case), or clears it when null or blank.
  void applyPromo(String? code) {
    final clean = code?.trim().toUpperCase();
    state = Basket(lines: state.lines, promoCode: (clean == null || clean.isEmpty) ? null : clean);
    _save();
  }

  void clear() {
    if (state.isEmpty && state.promoCode == null) return;
    state = const Basket();
    _save();
  }

  void _set(Map<String, int> lines) {
    state = Basket(lines: lines, promoCode: lines.isEmpty ? null : state.promoCode);
    _save();
  }

  void _save() {
    if (state.isEmpty) {
      unawaited(_prefs.remove(_key));
    } else {
      unawaited(_prefs.setString(_key, state.encode()));
    }
  }
}

/// Pieces in the basket.
final basketCountProvider = Provider<int>((ref) => ref.watch(basketProvider.select((b) => b.count)));

/// The items total from the price list, in paise: what the cart bar shows before the server's quote.
final basketEstimateProvider = Provider<int>((ref) {
  final lines = ref.watch(basketProvider.select((b) => b.lines));
  final items = ref.watch(catalogItemsProvider);
  var total = 0;
  for (final e in lines.entries) {
    final item = items[e.key];
    if (item != null) total += item.effectivePricePaise.round() * e.value;
  }
  return total;
});
