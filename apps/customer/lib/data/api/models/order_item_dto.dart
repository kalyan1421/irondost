// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'item_unit.dart';

part 'order_item_dto.g.dart';

@JsonSerializable()
class OrderItemDto {
  const OrderItemDto({
    required this.id,
    required this.catalogItemId,
    required this.name,
    required this.unit,
    required this.unitPricePaise,
    required this.quantity,
    required this.lineTotalPaise,
  });
  
  factory OrderItemDto.fromJson(Map<String, Object?> json) => _$OrderItemDtoFromJson(json);
  
  final String id;
  final String? catalogItemId;
  final String name;
  final ItemUnit unit;
  final num unitPricePaise;
  final num quantity;
  final num lineTotalPaise;

  Map<String, Object?> toJson() => _$OrderItemDtoToJson(this);
}
