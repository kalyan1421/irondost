// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'slot_definition_dto.dart';

part 'public_config_dto.g.dart';

@JsonSerializable()
class PublicConfigDto {
  const PublicConfigDto({
    required this.appName,
    required this.supportPhone,
    required this.supportEmail,
    required this.minOrderPaise,
    required this.deliveryFeePaise,
    required this.freeDeliveryAbovePaise,
    required this.minTurnaroundHours,
    required this.maxAdvanceDays,
    required this.slots,
  });
  
  factory PublicConfigDto.fromJson(Map<String, Object?> json) => _$PublicConfigDtoFromJson(json);
  
  final String appName;
  final String? supportPhone;
  final String? supportEmail;
  final num minOrderPaise;
  final num deliveryFeePaise;
  final num? freeDeliveryAbovePaise;
  final num minTurnaroundHours;
  final num maxAdvanceDays;
  final List<SlotDefinitionDto> slots;

  Map<String, Object?> toJson() => _$PublicConfigDtoToJson(this);
}
