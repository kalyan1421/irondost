// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_area_check_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAreaCheckDto _$ServiceAreaCheckDtoFromJson(Map<String, dynamic> json) =>
    ServiceAreaCheckDto(
      serviceable: json['serviceable'] as bool,
      reason: json['reason'] == null
          ? null
          : NotServiceableReason.fromJson(json['reason'] as String),
      distanceKm: json['distanceKm'] as num?,
    );

Map<String, dynamic> _$ServiceAreaCheckDtoToJson(
  ServiceAreaCheckDto instance,
) => <String, dynamic>{
  'serviceable': instance.serviceable,
  'reason': instance.reason,
  'distanceKm': instance.distanceKm,
};
