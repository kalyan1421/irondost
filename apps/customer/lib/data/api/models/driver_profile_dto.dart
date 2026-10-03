// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'driver_profile_dto.g.dart';

@JsonSerializable()
class DriverProfileDto {
  const DriverProfileDto({
    required this.vehicleNumber,
    required this.licenseNumber,
    required this.isOnline,
    required this.latitude,
    required this.longitude,
    required this.locationUpdatedAt,
  });
  
  factory DriverProfileDto.fromJson(Map<String, Object?> json) => _$DriverProfileDtoFromJson(json);
  
  final String? vehicleNumber;
  final String? licenseNumber;
  final bool isOnline;
  final num? latitude;
  final num? longitude;
  final DateTime? locationUpdatedAt;

  Map<String, Object?> toJson() => _$DriverProfileDtoToJson(this);
}
