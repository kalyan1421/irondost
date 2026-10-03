// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  id: json['id'] as String,
  phone: json['phone'] as String,
  name: json['name'] as String?,
  email: json['email'] as String?,
  role: Role.fromJson(json['role'] as String),
  isActive: json['isActive'] as bool,
  isProfileComplete: json['isProfileComplete'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'phone': instance.phone,
  'name': instance.name,
  'email': instance.email,
  'role': instance.role,
  'isActive': instance.isActive,
  'isProfileComplete': instance.isProfileComplete,
  'createdAt': instance.createdAt.toIso8601String(),
};
