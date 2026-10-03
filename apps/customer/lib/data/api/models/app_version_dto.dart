// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'client_app.dart';
import 'device_platform.dart';

part 'app_version_dto.g.dart';

@JsonSerializable()
class AppVersionDto {
  const AppVersionDto({
    required this.app,
    required this.platform,
    required this.minVersion,
    required this.latestVersion,
    required this.storeUrl,
    required this.message,
  });
  
  factory AppVersionDto.fromJson(Map<String, Object?> json) => _$AppVersionDtoFromJson(json);
  
  final ClientApp app;
  final DevicePlatform platform;
  final String minVersion;
  final String latestVersion;
  final String? storeUrl;
  final String? message;

  Map<String, Object?> toJson() => _$AppVersionDtoToJson(this);
}
