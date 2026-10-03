import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../data/api_client.dart';

/// Promotions running now: Home's offer card, the Offers tab and the basket's "Apply a code" sheet.
final promotionsProvider = FutureProvider<List<PromotionDto>>((ref) => ref.watch(apiProvider).promotions.promotionsControllerActive());

/// "Up to ₹100 · Min. order ₹299", plus "Valid till 31 Oct" when [withValidity].
String promoTerms(PromotionDto promo, {bool withValidity = false}) => [
      if (promo.maxDiscountPaise != null) 'Up to ${rupees(promo.maxDiscountPaise!)}',
      if (promo.minOrderPaise > 0) 'Min. order ${rupees(promo.minOrderPaise)}',
      if (withValidity) 'Valid till ${DateFormat('d MMM').format(promo.validTo.toLocal())}',
    ].join(' · ');
