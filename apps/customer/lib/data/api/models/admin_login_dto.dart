// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'admin_login_dto.g.dart';

@JsonSerializable()
class AdminLoginDto {
  const AdminLoginDto({
    required this.email,
    required this.password,
  });
  
  factory AdminLoginDto.fromJson(Map<String, Object?> json) => _$AdminLoginDtoFromJson(json);
  
  final String email;
  final String password;

  Map<String, Object?> toJson() => _$AdminLoginDtoToJson(this);
}
