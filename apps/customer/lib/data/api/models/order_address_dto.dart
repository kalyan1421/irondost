// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'order_address_dto.g.dart';

@JsonSerializable()
class OrderAddressDto {
  const OrderAddressDto({
    required this.label,
    required this.formatted,
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
    required this.contactName,
    required this.contactPhone,
  });
  
  factory OrderAddressDto.fromJson(Map<String, Object?> json) => _$OrderAddressDtoFromJson(json);
  
  final String label;
  final String formatted;
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
  final String? contactName;
  final String contactPhone;

  Map<String, Object?> toJson() => _$OrderAddressDtoToJson(this);
}
