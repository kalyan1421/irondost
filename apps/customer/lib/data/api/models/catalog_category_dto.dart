// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'catalog_item_dto.dart';

part 'catalog_category_dto.g.dart';

@JsonSerializable()
class CatalogCategoryDto {
  const CatalogCategoryDto({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
    required this.sortOrder,
    required this.isActive,
    required this.items,
  });
  
  factory CatalogCategoryDto.fromJson(Map<String, Object?> json) => _$CatalogCategoryDtoFromJson(json);
  
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final num sortOrder;
  final bool isActive;
  final List<CatalogItemDto> items;

  Map<String, Object?> toJson() => _$CatalogCategoryDtoToJson(this);
}
