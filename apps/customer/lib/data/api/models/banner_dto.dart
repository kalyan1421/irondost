// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'banner_dto.g.dart';

@JsonSerializable()
class BannerDto {
  const BannerDto({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.linkUrl,
    required this.sortOrder,
    required this.isActive,
  });
  
  factory BannerDto.fromJson(Map<String, Object?> json) => _$BannerDtoFromJson(json);
  
  final String id;
  final String imageUrl;
  final String? title;
  final String? linkUrl;
  final num sortOrder;
  final bool isActive;

  Map<String, Object?> toJson() => _$BannerDtoToJson(this);
}
