// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'client_app.dart';
import 'device_platform.dart';

part 'upsert_app_version_dto.g.dart';

@JsonSerializable()
class UpsertAppVersionDto {
  const UpsertAppVersionDto({
    required this.app,
    required this.platform,
    required this.minVersion,
    required this.latestVersion,
    this.storeUrl,
    this.message,
  });
  
  factory UpsertAppVersionDto.fromJson(Map<String, Object?> json) => _$UpsertAppVersionDtoFromJson(json);
  
  final ClientApp app;
  final DevicePlatform platform;

  /// Older versions are forced to update
  final String minVersion;

  /// Older versions see an optional update prompt
  final String latestVersion;
  final String? storeUrl;
  final String? message;

  Map<String, Object?> toJson() => _$UpsertAppVersionDtoToJson(this);
}
