// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'register_area_interest_dto.g.dart';

@JsonSerializable()
class RegisterAreaInterestDto {
  const RegisterAreaInterestDto({
    required this.addressId,
  });
  
  factory RegisterAreaInterestDto.fromJson(Map<String, Object?> json) => _$RegisterAreaInterestDtoFromJson(json);
  
  /// One of the signed-in customer's saved addresses. The place is read from the saved address, never from the request.
  final String addressId;

  Map<String, Object?> toJson() => _$RegisterAreaInterestDtoToJson(this);
}
