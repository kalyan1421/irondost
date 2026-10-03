// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'create_address_dto.g.dart';

@JsonSerializable()
class CreateAddressDto {
  const CreateAddressDto({
    required this.houseNo,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    this.building,
    this.area,
    this.landmark,
    this.latitude,
    this.longitude,
    this.label = 'Home',
    this.isPrimary = false,
  });
  
  factory CreateAddressDto.fromJson(Map<String, Object?> json) => _$CreateAddressDtoFromJson(json);
  
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

  Map<String, Object?> toJson() => _$CreateAddressDtoToJson(this);
}
