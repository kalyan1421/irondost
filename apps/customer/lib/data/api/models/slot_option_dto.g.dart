// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slot_option_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SlotOptionDto _$SlotOptionDtoFromJson(Map<String, dynamic> json) =>
    SlotOptionDto(
      date: json['date'] as String,
      slot: TimeSlot.fromJson(json['slot'] as String),
      label: json['label'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      available: json['available'] as bool,
    );

Map<String, dynamic> _$SlotOptionDtoToJson(SlotOptionDto instance) =>
    <String, dynamic>{
      'date': instance.date,
      'slot': instance.slot,
      'label': instance.label,
      'startsAt': instance.startsAt.toIso8601String(),
      'endsAt': instance.endsAt.toIso8601String(),
      'available': instance.available,
    };
