// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'admin_login_result_dto.g.dart';

@JsonSerializable()
class AdminLoginResultDto {
  const AdminLoginResultDto({
    required this.token,
  });
  
  factory AdminLoginResultDto.fromJson(Map<String, Object?> json) => _$AdminLoginResultDtoFromJson(json);
  
  final String token;

  Map<String, Object?> toJson() => _$AdminLoginResultDtoToJson(this);
}
