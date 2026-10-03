// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressDto _$AddressDtoFromJson(Map<String, dynamic> json) => AddressDto(
  id: json['id'] as String,
  label: json['label'] as String,
  houseNo: json['houseNo'] as String,
  building: json['building'] as String?,
  street: json['street'] as String,
  area: json['area'] as String?,
  landmark: json['landmark'] as String?,
  city: json['city'] as String,
  state: json['state'] as String,
  pincode: json['pincode'] as String,
  latitude: json['latitude'] as num?,
  longitude: json['longitude'] as num?,
  isPrimary: json['isPrimary'] as bool,
  formatted: json['formatted'] as String,
  serviceable: json['serviceable'] as bool,
  notServiceableReason: json['notServiceableReason'] == null
      ? null
      : NotServiceableReason.fromJson(json['notServiceableReason'] as String),
);

Map<String, dynamic> _$AddressDtoToJson(AddressDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'houseNo': instance.houseNo,
      'building': instance.building,
      'street': instance.street,
      'area': instance.area,
      'landmark': instance.landmark,
      'city': instance.city,
      'state': instance.state,
      'pincode': instance.pincode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'isPrimary': instance.isPrimary,
      'formatted': instance.formatted,
      'serviceable': instance.serviceable,
      'notServiceableReason': instance.notServiceableReason,
    };
