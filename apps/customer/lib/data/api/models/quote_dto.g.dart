// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuoteDto _$QuoteDtoFromJson(Map<String, dynamic> json) => QuoteDto(
  lines: (json['lines'] as List<dynamic>)
      .map((e) => QuoteLineDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  subtotalPaise: json['subtotalPaise'] as num,
  discountPaise: json['discountPaise'] as num,
  deliveryFeePaise: json['deliveryFeePaise'] as num,
  totalPaise: json['totalPaise'] as num,
  promoCode: json['promoCode'] as String?,
  promoError: json['promoError'] == null
      ? null
      : QuoteDtoPromoError.fromJson(json['promoError'] as String),
  promoShortfallPaise: json['promoShortfallPaise'] as num?,
  minOrderShortfallPaise: json['minOrderShortfallPaise'] as num?,
  canPlaceOrder: json['canPlaceOrder'] as bool,
);

Map<String, dynamic> _$QuoteDtoToJson(QuoteDto instance) => <String, dynamic>{
  'lines': instance.lines,
  'subtotalPaise': instance.subtotalPaise,
  'discountPaise': instance.discountPaise,
  'deliveryFeePaise': instance.deliveryFeePaise,
  'totalPaise': instance.totalPaise,
  'promoCode': instance.promoCode,
  'promoError': instance.promoError,
  'promoShortfallPaise': instance.promoShortfallPaise,
  'minOrderShortfallPaise': instance.minOrderShortfallPaise,
  'canPlaceOrder': instance.canPlaceOrder,
};
