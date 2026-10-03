// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banner_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BannerDto _$BannerDtoFromJson(Map<String, dynamic> json) => BannerDto(
  id: json['id'] as String,
  imageUrl: json['imageUrl'] as String,
  title: json['title'] as String?,
  linkUrl: json['linkUrl'] as String?,
  sortOrder: json['sortOrder'] as num,
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$BannerDtoToJson(BannerDto instance) => <String, dynamic>{
  'id': instance.id,
  'imageUrl': instance.imageUrl,
  'title': instance.title,
  'linkUrl': instance.linkUrl,
  'sortOrder': instance.sortOrder,
  'isActive': instance.isActive,
};
