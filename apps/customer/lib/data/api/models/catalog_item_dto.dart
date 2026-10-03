// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'item_unit.dart';

part 'catalog_item_dto.g.dart';

@JsonSerializable()
class CatalogItemDto {
  const CatalogItemDto({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.unit,
    required this.pricePaise,
    required this.offerPricePaise,
    required this.effectivePricePaise,
    required this.imageUrl,
    required this.sortOrder,
    required this.isActive,
  });
  
  factory CatalogItemDto.fromJson(Map<String, Object?> json) => _$CatalogItemDtoFromJson(json);
  
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final ItemUnit unit;
  final num pricePaise;
  final num? offerPricePaise;

  /// What the customer pays per unit.
  final num effectivePricePaise;
  final String? imageUrl;
  final num sortOrder;
  final bool isActive;

  Map<String, Object?> toJson() => _$CatalogItemDtoToJson(this);
}
