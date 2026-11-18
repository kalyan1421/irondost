// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'payment_provider.dart';

part 'order_payment_dto.g.dart';

@JsonSerializable()
class OrderPaymentDto {
  const OrderPaymentDto({
    required this.id,
    required this.provider,
    required this.amountPaise,
    required this.reference,
    required this.capturedAt,
  });
  
  factory OrderPaymentDto.fromJson(Map<String, Object?> json) => _$OrderPaymentDtoFromJson(json);
  
  final String id;
  final PaymentProvider provider;
  final num amountPaise;
  final String? reference;
  final DateTime capturedAt;

  Map<String, Object?> toJson() => _$OrderPaymentDtoToJson(this);
}
