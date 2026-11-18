// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_me_dto.g.dart';

@JsonSerializable()
class UpdateMeDto {
  const UpdateMeDto({
    this.name,
    this.email,
    this.phone,
  });
  
  factory UpdateMeDto.fromJson(Map<String, Object?> json) => _$UpdateMeDtoFromJson(json);
  
  final String? name;
  final String? email;

  /// Customers only, and only while they have no sign-in number. Any common Indian format; stored as +91XXXXXXXXXX without an SMS code.
  final String? phone;

  Map<String, Object?> toJson() => _$UpdateMeDtoToJson(this);
}
