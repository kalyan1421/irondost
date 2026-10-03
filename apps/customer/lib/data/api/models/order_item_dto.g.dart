// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItemDto _$OrderItemDtoFromJson(Map<String, dynamic> json) => OrderItemDto(
  id: json['id'] as String,
  catalogItemId: json['catalogItemId'] as String?,
  name: json['name'] as String,
  unit: ItemUnit.fromJson(json['unit'] as String),
  unitPricePaise: json['unitPricePaise'] as num,
  quantity: json['quantity'] as num,
  lineTotalPaise: json['lineTotalPaise'] as num,
);

Map<String, dynamic> _$OrderItemDtoToJson(OrderItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'catalogItemId': instance.catalogItemId,
      'name': instance.name,
      'unit': instance.unit,
      'unitPricePaise': instance.unitPricePaise,
      'quantity': instance.quantity,
      'lineTotalPaise': instance.lineTotalPaise,
    };
