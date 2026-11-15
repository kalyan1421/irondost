// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reschedule_order_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RescheduleOrderDto _$RescheduleOrderDtoFromJson(Map<String, dynamic> json) =>
    RescheduleOrderDto(
      pickupDate: json['pickupDate'] as String,
      pickupSlot: TimeSlot.fromJson(json['pickupSlot'] as String),
      deliveryDate: json['deliveryDate'] as String,
      deliverySlot: TimeSlot.fromJson(json['deliverySlot'] as String),
    );

Map<String, dynamic> _$RescheduleOrderDtoToJson(RescheduleOrderDto instance) =>
    <String, dynamic>{
      'pickupDate': instance.pickupDate,
      'pickupSlot': instance.pickupSlot,
      'deliveryDate': instance.deliveryDate,
      'deliverySlot': instance.deliverySlot,
    };
