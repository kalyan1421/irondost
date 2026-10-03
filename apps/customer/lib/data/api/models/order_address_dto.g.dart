// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_address_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderAddressDto _$OrderAddressDtoFromJson(Map<String, dynamic> json) =>
    OrderAddressDto(
      label: json['label'] as String,
      formatted: json['formatted'] as String,
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
      contactName: json['contactName'] as String?,
      contactPhone: json['contactPhone'] as String,
    );

Map<String, dynamic> _$OrderAddressDtoToJson(OrderAddressDto instance) =>
    <String, dynamic>{
      'label': instance.label,
      'formatted': instance.formatted,
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
      'contactName': instance.contactName,
      'contactPhone': instance.contactPhone,
    };
