// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuoteRequestDto _$QuoteRequestDtoFromJson(Map<String, dynamic> json) =>
    QuoteRequestDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderLineInput.fromJson(e as Map<String, dynamic>))
          .toList(),
      promoCode: json['promoCode'] as String?,
    );

Map<String, dynamic> _$QuoteRequestDtoToJson(QuoteRequestDto instance) =>
    <String, dynamic>{'items': instance.items, 'promoCode': instance.promoCode};
