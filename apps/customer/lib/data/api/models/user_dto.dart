// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'role.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class UserDto {
  const UserDto({
    required this.id,
    required this.phone,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.isProfileComplete,
    required this.createdAt,
  });
  
  factory UserDto.fromJson(Map<String, Object?> json) => _$UserDtoFromJson(json);
  
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final Role role;
  final bool isActive;

  /// False until the customer has entered a name.
  final bool isProfileComplete;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$UserDtoToJson(this);
}
