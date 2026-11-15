// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'quote_dto_promo_error.dart';
import 'quote_line_dto.dart';

part 'quote_dto.g.dart';

@JsonSerializable()
class QuoteDto {
  const QuoteDto({
    required this.lines,
    required this.subtotalPaise,
    required this.discountPaise,
    required this.deliveryFeePaise,
    required this.totalPaise,
    required this.freeTravelShortfallPaise,
    required this.promoCode,
    required this.promoError,
    required this.promoShortfallPaise,
    required this.minOrderShortfallPaise,
    required this.canPlaceOrder,
  });
  
  factory QuoteDto.fromJson(Map<String, Object?> json) => _$QuoteDtoFromJson(json);
  
  final List<QuoteLineDto> lines;
  final num subtotalPaise;
  final num discountPaise;

  /// The flat travel charge: 0 once the items total (before any coupon) reaches the free-from amount.
  final num deliveryFeePaise;
  final num totalPaise;

  /// How much more of clothes (items total before any coupon) makes travel free. Null when travel is already free or there is no threshold.
  final num? freeTravelShortfallPaise;
  final String? promoCode;

  /// Why the promo code was not applied, if it was not.
  final QuoteDtoPromoError? promoError;
  final num? promoShortfallPaise;
  final num? minOrderShortfallPaise;
  final bool canPlaceOrder;

  Map<String, Object?> toJson() => _$QuoteDtoToJson(this);
}
