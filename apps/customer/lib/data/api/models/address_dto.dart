// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'not_serviceable_reason.dart';

part 'address_dto.g.dart';

@JsonSerializable()
class AddressDto {
  const AddressDto({
    required this.id,
    required this.label,
    required this.houseNo,
    required this.building,
    required this.street,
    required this.area,
    required this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.isPrimary,
    required this.formatted,
    required this.serviceable,
    required this.notServiceableReason,
  });
  
  factory AddressDto.fromJson(Map<String, Object?> json) => _$AddressDtoFromJson(json);
  
  final String id;
  final String label;
  final String houseNo;
  final String? building;
  final String street;
  final String? area;
  final String? landmark;
  final String city;
  final String state;
  final String pincode;
  final num? latitude;
  final num? longitude;
  final bool isPrimary;

  /// One-line address for display.
  final String formatted;

  /// Whether pickups can be booked here under the current service area.
  final bool serviceable;
  final NotServiceableReason? notServiceableReason;

  Map<String, Object?> toJson() => _$AddressDtoToJson(this);
}
