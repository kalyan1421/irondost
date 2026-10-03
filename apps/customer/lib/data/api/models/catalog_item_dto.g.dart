// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogItemDto _$CatalogItemDtoFromJson(Map<String, dynamic> json) =>
    CatalogItemDto(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      unit: ItemUnit.fromJson(json['unit'] as String),
      pricePaise: json['pricePaise'] as num,
      offerPricePaise: json['offerPricePaise'] as num?,
      effectivePricePaise: json['effectivePricePaise'] as num,
      imageUrl: json['imageUrl'] as String?,
      sortOrder: json['sortOrder'] as num,
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$CatalogItemDtoToJson(CatalogItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'categoryId': instance.categoryId,
      'name': instance.name,
      'description': instance.description,
      'unit': instance.unit,
      'pricePaise': instance.pricePaise,
      'offerPricePaise': instance.offerPricePaise,
      'effectivePricePaise': instance.effectivePricePaise,
      'imageUrl': instance.imageUrl,
      'sortOrder': instance.sortOrder,
      'isActive': instance.isActive,
    };
