// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeDto _$MeDtoFromJson(Map<String, dynamic> json) => MeDto(
  id: json['id'] as String,
  phone: json['phone'] as String?,
  phoneVerified: json['phoneVerified'] as bool,
  name: json['name'] as String?,
  email: json['email'] as String?,
  role: Role.fromJson(json['role'] as String),
  isActive: json['isActive'] as bool,
  isProfileComplete: json['isProfileComplete'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  driver: json['driver'] == null
      ? null
      : DriverProfileDto.fromJson(json['driver'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MeDtoToJson(MeDto instance) => <String, dynamic>{
  'id': instance.id,
  'phone': instance.phone,
  'phoneVerified': instance.phoneVerified,
  'name': instance.name,
  'email': instance.email,
  'role': instance.role,
  'isActive': instance.isActive,
  'isProfileComplete': instance.isProfileComplete,
  'createdAt': instance.createdAt.toIso8601String(),
  'driver': instance.driver,
};
