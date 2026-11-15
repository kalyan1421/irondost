// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_upload_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageUploadDto _$ImageUploadDtoFromJson(Map<String, dynamic> json) =>
    ImageUploadDto(
      url: json['url'] as String,
      width: json['width'] as num,
      height: json['height'] as num,
      bytes: json['bytes'] as num,
    );

Map<String, dynamic> _$ImageUploadDtoToJson(ImageUploadDto instance) =>
    <String, dynamic>{
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
      'bytes': instance.bytes,
    };
