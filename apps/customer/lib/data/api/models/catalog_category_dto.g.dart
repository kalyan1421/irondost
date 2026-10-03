// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_category_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogCategoryDto _$CatalogCategoryDtoFromJson(Map<String, dynamic> json) =>
    CatalogCategoryDto(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      imageUrl: json['imageUrl'] as String?,
      sortOrder: json['sortOrder'] as num,
      isActive: json['isActive'] as bool,
      items: (json['items'] as List<dynamic>)
          .map((e) => CatalogItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CatalogCategoryDtoToJson(CatalogCategoryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'imageUrl': instance.imageUrl,
      'sortOrder': instance.sortOrder,
      'isActive': instance.isActive,
      'items': instance.items,
    };
