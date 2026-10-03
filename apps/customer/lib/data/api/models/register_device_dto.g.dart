// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_device_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterDeviceDto _$RegisterDeviceDtoFromJson(Map<String, dynamic> json) =>
    RegisterDeviceDto(
      fcmToken: json['fcmToken'] as String,
      platform: DevicePlatform.fromJson(json['platform'] as String),
      app: ClientApp.fromJson(json['app'] as String),
    );

Map<String, dynamic> _$RegisterDeviceDtoToJson(RegisterDeviceDto instance) =>
    <String, dynamic>{
      'fcmToken': instance.fcmToken,
      'platform': instance.platform,
      'app': instance.app,
    };
