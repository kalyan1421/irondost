import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../data/api_client.dart';

/// Promotions running now: Home's offer card, the Offers tab and the basket's "Apply a code" sheet.
final promotionsProvider = FutureProvider<List<PromotionDto>>((ref) => ref.watch(apiProvider).promotions.promotionsControllerActive());

/// "Up to ₹100 · Min. order ₹299", plus "Once per customer" when [withLimit] and "Valid till 31 Oct" when [withValidity].
String promoTerms(PromotionDto promo, {bool withValidity = false, bool withLimit = false}) => [
      if (promo.maxDiscountPaise != null) 'Up to ${rupees(promo.maxDiscountPaise!)}',
      if (promo.minOrderPaise > 0) 'Min. order ${rupees(promo.minOrderPaise)}',
      if (withLimit && promo.perCustomerLimit != null) _limit(promo.perCustomerLimit!.toInt()),
      if (withValidity) 'Valid till ${DateFormat('d MMM').format(promo.validTo.toLocal())}',
    ].join(' · ');

String _limit(int n) => switch (n) {
      1 => 'Once per customer',
      2 => 'Twice per customer',
      _ => '$n times per customer',
    };

/// The short label on an offer: "20% off" or "₹50 off".
String promoBadge(PromotionDto promo) {
  final value = promo.discountValue;
  return switch (promo.discountType) {
    DiscountType.percent => '${value % 1 == 0 ? value.toInt() : value}% off',
    DiscountType.flat => '${rupees(value)} off',
    _ => 'Offer',
  };
}
