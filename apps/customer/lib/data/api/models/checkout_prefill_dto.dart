// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'checkout_prefill_dto.g.dart';

@JsonSerializable()
class CheckoutPrefillDto {
  const CheckoutPrefillDto({
    required this.name,
    required this.contact,
    required this.email,
  });
  
  factory CheckoutPrefillDto.fromJson(Map<String, Object?> json) => _$CheckoutPrefillDtoFromJson(json);
  
  final String? name;
  final String contact;
  final String? email;

  Map<String, Object?> toJson() => _$CheckoutPrefillDtoToJson(this);
}
