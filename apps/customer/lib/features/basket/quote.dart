import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/api_client.dart';
import 'basket.dart';

/// The server's price for a basket. The API is the only source of truth for totals, discounts and
/// delivery fees; the app never adds them up itself.
abstract class QuoteRepository {
  Future<QuoteDto> quote(List<OrderLineInput> items, String? promoCode);
}

class ApiQuoteRepository implements QuoteRepository {
  ApiQuoteRepository(this._api);
  final IronDostApi _api;

  @override
  Future<QuoteDto> quote(List<OrderLineInput> items, String? promoCode) async {
    try {
      return await _api.orders.ordersControllerQuote(body: QuoteRequestDto(items: items, promoCode: promoCode));
    } on DioException catch (e) {
      throw ApiFailure.from(e);
    }
  }
}

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) => ApiQuoteRepository(ref.watch(apiProvider)));

/// A burst of stepper taps sends one request.
const quoteDebounce = Duration(milliseconds: 300);

/// The quote for what is in the basket now; null while the basket is empty.
///
/// A change to the basket restarts it. While it reloads the screen keeps showing the previous
/// quote, dimmed. If the API says an item is gone, the item leaves the basket and the quote reruns.
final quoteProvider = FutureProvider.autoDispose<QuoteDto?>((ref) async {
  final basket = ref.watch(basketProvider);
  if (basket.isEmpty) return null;

  var superseded = false;
  ref.onDispose(() => superseded = true);
  await Future<void>.delayed(quoteDebounce);
  if (superseded) return null;

  try {
    return await ref.read(quoteRepositoryProvider).quote(basket.items, basket.promoCode);
  } on ApiFailure catch (e) {
    final gone = e.details?['catalogItemIds'];
    if (e.code == 'ITEM_UNAVAILABLE' && gone is List) {
      for (final id in gone) {
        ref.read(basketProvider.notifier).delete('$id');
      }
      return null;
    }
    rethrow;
  }
});

/// Why a promo code did not apply, in the customer's words. Null when it applied (or none was tried).
String? promoErrorText(QuoteDtoPromoError? error, {num? shortfallPaise}) => switch (error) {
      null => null,
      QuoteDtoPromoError.promoNotFound => "We couldn't find that code. Check the spelling.",
      QuoteDtoPromoError.promoExpired => 'This code has expired.',
      QuoteDtoPromoError.promoLimitReached => "You've already used this code.",
      QuoteDtoPromoError.promoMinOrder =>
        shortfallPaise == null ? 'Your basket is below the minimum for this code.' : 'Add ${rupees(shortfallPaise)} more to use this code.',
      QuoteDtoPromoError.$unknown => "This code can't be used right now.",
    };
