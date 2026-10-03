// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_address_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateAddressDto _$CreateAddressDtoFromJson(Map<String, dynamic> json) =>
    CreateAddressDto(
      houseNo: json['houseNo'] as String,
      street: json['street'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
      building: json['building'] as String?,
      area: json['area'] as String?,
      landmark: json['landmark'] as String?,
      latitude: json['latitude'] as num?,
      longitude: json['longitude'] as num?,
      label: json['label'] as String? ?? 'Home',
      isPrimary: json['isPrimary'] as bool? ?? false,
    );

Map<String, dynamic> _$CreateAddressDtoToJson(CreateAddressDto instance) =>
    <String, dynamic>{
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
    };
