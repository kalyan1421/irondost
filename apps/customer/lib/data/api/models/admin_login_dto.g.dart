// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_login_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminLoginDto _$AdminLoginDtoFromJson(Map<String, dynamic> json) =>
    AdminLoginDto(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$AdminLoginDtoToJson(AdminLoginDto instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};
