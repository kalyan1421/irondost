// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote_line_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuoteLineDto _$QuoteLineDtoFromJson(Map<String, dynamic> json) => QuoteLineDto(
  catalogItemId: json['catalogItemId'] as String,
  name: json['name'] as String,
  unit: ItemUnit.fromJson(json['unit'] as String),
  unitPricePaise: json['unitPricePaise'] as num,
  quantity: json['quantity'] as num,
  lineTotalPaise: json['lineTotalPaise'] as num,
);

Map<String, dynamic> _$QuoteLineDtoToJson(QuoteLineDto instance) =>
    <String, dynamic>{
      'catalogItemId': instance.catalogItemId,
      'name': instance.name,
      'unit': instance.unit,
      'unitPricePaise': instance.unitPricePaise,
      'quantity': instance.quantity,
      'lineTotalPaise': instance.lineTotalPaise,
    };
