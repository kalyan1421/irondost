// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'area_interest_dto.g.dart';

@JsonSerializable()
class AreaInterestDto {
  const AreaInterestDto({
    required this.id,
    required this.pincode,
    required this.locality,
    required this.createdAt,
  });
  
  factory AreaInterestDto.fromJson(Map<String, Object?> json) => _$AreaInterestDtoFromJson(json);
  
  final String id;
  final String pincode;
  final String locality;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$AreaInterestDtoToJson(this);
}
