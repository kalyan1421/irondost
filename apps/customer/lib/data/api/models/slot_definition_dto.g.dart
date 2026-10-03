// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slot_definition_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SlotDefinitionDto _$SlotDefinitionDtoFromJson(Map<String, dynamic> json) =>
    SlotDefinitionDto(
      slot: TimeSlot.fromJson(json['slot'] as String),
      label: json['label'] as String,
    );

Map<String, dynamic> _$SlotDefinitionDtoToJson(SlotDefinitionDto instance) =>
    <String, dynamic>{'slot': instance.slot, 'label': instance.label};
