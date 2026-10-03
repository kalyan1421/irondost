// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upsert_app_version_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpsertAppVersionDto _$UpsertAppVersionDtoFromJson(Map<String, dynamic> json) =>
    UpsertAppVersionDto(
      app: ClientApp.fromJson(json['app'] as String),
      platform: DevicePlatform.fromJson(json['platform'] as String),
      minVersion: json['minVersion'] as String,
      latestVersion: json['latestVersion'] as String,
      storeUrl: json['storeUrl'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$UpsertAppVersionDtoToJson(
  UpsertAppVersionDto instance,
) => <String, dynamic>{
  'app': instance.app,
  'platform': instance.platform,
  'minVersion': instance.minVersion,
  'latestVersion': instance.latestVersion,
  'storeUrl': instance.storeUrl,
  'message': instance.message,
};
