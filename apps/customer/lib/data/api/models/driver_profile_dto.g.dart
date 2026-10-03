// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverProfileDto _$DriverProfileDtoFromJson(Map<String, dynamic> json) =>
    DriverProfileDto(
      vehicleNumber: json['vehicleNumber'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      isOnline: json['isOnline'] as bool,
      latitude: json['latitude'] as num?,
      longitude: json['longitude'] as num?,
      locationUpdatedAt: json['locationUpdatedAt'] == null
          ? null
          : DateTime.parse(json['locationUpdatedAt'] as String),
    );

Map<String, dynamic> _$DriverProfileDtoToJson(DriverProfileDto instance) =>
    <String, dynamic>{
      'vehicleNumber': instance.vehicleNumber,
      'licenseNumber': instance.licenseNumber,
      'isOnline': instance.isOnline,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'locationUpdatedAt': instance.locationUpdatedAt?.toIso8601String(),
    };
