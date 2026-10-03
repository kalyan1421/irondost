// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'time_slot.dart';

part 'slot_option_dto.g.dart';

@JsonSerializable()
class SlotOptionDto {
  const SlotOptionDto({
    required this.date,
    required this.slot,
    required this.label,
    required this.startsAt,
    required this.endsAt,
    required this.available,
  });
  
  factory SlotOptionDto.fromJson(Map<String, Object?> json) => _$SlotOptionDtoFromJson(json);
  
  final String date;
  final TimeSlot slot;
  final String label;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool available;

  Map<String, Object?> toJson() => _$SlotOptionDtoToJson(this);
}
