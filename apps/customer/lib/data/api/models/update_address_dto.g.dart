// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_address_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateAddressDto _$UpdateAddressDtoFromJson(Map<String, dynamic> json) =>
    UpdateAddressDto(
      houseNo: json['houseNo'] as String?,
      building: json['building'] as String?,
      street: json['street'] as String?,
      area: json['area'] as String?,
      landmark: json['landmark'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      latitude: json['latitude'] as num?,
      longitude: json['longitude'] as num?,
      label: json['label'] as String? ?? 'Home',
      isPrimary: json['isPrimary'] as bool? ?? false,
    );

Map<String, dynamic> _$UpdateAddressDtoToJson(UpdateAddressDto instance) =>
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
