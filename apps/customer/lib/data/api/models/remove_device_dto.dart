// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'remove_device_dto.g.dart';

@JsonSerializable()
class RemoveDeviceDto {
  const RemoveDeviceDto({
    required this.fcmToken,
  });
  
  factory RemoveDeviceDto.fromJson(Map<String, Object?> json) => _$RemoveDeviceDtoFromJson(json);
  
  final String fcmToken;

  Map<String, Object?> toJson() => _$RemoveDeviceDtoToJson(this);
}
