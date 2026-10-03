// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_line_input.dart';
import 'payment_method.dart';
import 'time_slot.dart';

part 'place_order_dto.g.dart';

@JsonSerializable()
class PlaceOrderDto {
  const PlaceOrderDto({
    required this.items,
    required this.pickupDate,
    required this.pickupSlot,
    required this.deliveryDate,
    required this.deliverySlot,
    required this.pickupAddressId,
    required this.paymentMethod,
    this.promoCode,
    this.deliveryAddressId,
    this.instructions,
  });
  
  factory PlaceOrderDto.fromJson(Map<String, Object?> json) => _$PlaceOrderDtoFromJson(json);
  
  final List<OrderLineInput> items;
  final String? promoCode;

  /// IST calendar date
  final String pickupDate;
  final TimeSlot pickupSlot;
  final String deliveryDate;
  final TimeSlot deliverySlot;
  final String pickupAddressId;

  /// Defaults to the pickup address
  final String? deliveryAddressId;
  final PaymentMethod paymentMethod;
  final String? instructions;

  Map<String, Object?> toJson() => _$PlaceOrderDtoToJson(this);
}
