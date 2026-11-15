// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'area_interest_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AreaInterestDto _$AreaInterestDtoFromJson(Map<String, dynamic> json) =>
    AreaInterestDto(
      id: json['id'] as String,
      pincode: json['pincode'] as String,
      locality: json['locality'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AreaInterestDtoToJson(AreaInterestDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pincode': instance.pincode,
      'locality': instance.locality,
      'createdAt': instance.createdAt.toIso8601String(),
    };
