// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'time_slot.dart';

part 'slot_definition_dto.g.dart';

@JsonSerializable()
class SlotDefinitionDto {
  const SlotDefinitionDto({
    required this.slot,
    required this.label,
  });
  
  factory SlotDefinitionDto.fromJson(Map<String, Object?> json) => _$SlotDefinitionDtoFromJson(json);
  
  final TimeSlot slot;
  final String label;

  Map<String, Object?> toJson() => _$SlotDefinitionDtoToJson(this);
}
