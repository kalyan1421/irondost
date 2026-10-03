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
  });
  
  factory UpdateMeDto.fromJson(Map<String, Object?> json) => _$UpdateMeDtoFromJson(json);
  
  final String? name;
  final String? email;

  Map<String, Object?> toJson() => _$UpdateMeDtoToJson(this);
}
