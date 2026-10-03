// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'client_app.dart';
import 'device_platform.dart';

part 'register_device_dto.g.dart';

@JsonSerializable()
class RegisterDeviceDto {
  const RegisterDeviceDto({
    required this.fcmToken,
    required this.platform,
    required this.app,
  });
  
  factory RegisterDeviceDto.fromJson(Map<String, Object?> json) => _$RegisterDeviceDtoFromJson(json);
  
  final String fcmToken;
  final DevicePlatform platform;
  final ClientApp app;

  Map<String, Object?> toJson() => _$RegisterDeviceDtoToJson(this);
}
