// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'time_slot.dart';

part 'reschedule_order_dto.g.dart';

@JsonSerializable()
class RescheduleOrderDto {
  const RescheduleOrderDto({
    required this.pickupDate,
    required this.pickupSlot,
    required this.deliveryDate,
    required this.deliverySlot,
  });
  
  factory RescheduleOrderDto.fromJson(Map<String, Object?> json) => _$RescheduleOrderDtoFromJson(json);
  
  /// New pickup date (IST calendar date)
  final String pickupDate;
  final TimeSlot pickupSlot;

  /// Delivery date. Send the current one to keep it; it is accepted only if it still follows the new pickup by the minimum turnaround.
  final String deliveryDate;
  final TimeSlot deliverySlot;

  Map<String, Object?> toJson() => _$RescheduleOrderDtoToJson(this);
}
