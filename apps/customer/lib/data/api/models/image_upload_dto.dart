// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'image_upload_dto.g.dart';

@JsonSerializable()
class ImageUploadDto {
  const ImageUploadDto({
    required this.url,
    required this.width,
    required this.height,
    required this.bytes,
  });
  
  factory ImageUploadDto.fromJson(Map<String, Object?> json) => _$ImageUploadDtoFromJson(json);
  
  /// Public URL to save in imageUrl fields
  final String url;
  final num width;
  final num height;

  /// Stored size in bytes
  final num bytes;

  Map<String, Object?> toJson() => _$ImageUploadDtoToJson(this);
}
