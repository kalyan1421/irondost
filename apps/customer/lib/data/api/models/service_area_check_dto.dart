// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'not_serviceable_reason.dart';

part 'service_area_check_dto.g.dart';

@JsonSerializable()
class ServiceAreaCheckDto {
  const ServiceAreaCheckDto({
    required this.serviceable,
    required this.reason,
    required this.distanceKm,
  });
  
  factory ServiceAreaCheckDto.fromJson(Map<String, Object?> json) => _$ServiceAreaCheckDtoFromJson(json);
  
  final bool serviceable;
  final NotServiceableReason? reason;

  /// Distance from the hub when a radius applies
  final num? distanceKm;

  Map<String, Object?> toJson() => _$ServiceAreaCheckDtoToJson(this);
}
