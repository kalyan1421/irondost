// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adjustment_line_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdjustmentLineDto _$AdjustmentLineDtoFromJson(Map<String, dynamic> json) =>
    AdjustmentLineDto(
      catalogItemId: json['catalogItemId'] as String?,
      name: json['name'] as String,
      unit: ItemUnit.fromJson(json['unit'] as String),
      unitPricePaise: json['unitPricePaise'] as num,
      quantity: json['quantity'] as num,
      lineTotalPaise: json['lineTotalPaise'] as num,
    );

Map<String, dynamic> _$AdjustmentLineDtoToJson(AdjustmentLineDto instance) =>
    <String, dynamic>{
      'catalogItemId': instance.catalogItemId,
      'name': instance.name,
      'unit': instance.unit,
      'unitPricePaise': instance.unitPricePaise,
      'quantity': instance.quantity,
      'lineTotalPaise': instance.lineTotalPaise,
    };
