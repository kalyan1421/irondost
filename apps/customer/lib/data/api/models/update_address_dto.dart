// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_address_dto.g.dart';

@JsonSerializable()
class UpdateAddressDto {
  const UpdateAddressDto({
    this.houseNo,
    this.building,
    this.street,
    this.area,
    this.landmark,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.label = 'Home',
    this.isPrimary = false,
  });
  
  factory UpdateAddressDto.fromJson(Map<String, Object?> json) => _$UpdateAddressDtoFromJson(json);
  
  final String label;
  final String? houseNo;
  final String? building;
  final String? street;
  final String? area;
  final String? landmark;
  final String? city;
  final String? state;
  final String? pincode;
  final num? latitude;
  final num? longitude;
  final bool isPrimary;

  Map<String, Object?> toJson() => _$UpdateAddressDtoToJson(this);
}
