// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'person_ref_dto.g.dart';

@JsonSerializable()
class PersonRefDto {
  const PersonRefDto({
    required this.id,
    required this.name,
    required this.phone,
  });
  
  factory PersonRefDto.fromJson(Map<String, Object?> json) => _$PersonRefDtoFromJson(json);
  
  final String id;
  final String? name;
  final String phone;

  Map<String, Object?> toJson() => _$PersonRefDtoToJson(this);
}
