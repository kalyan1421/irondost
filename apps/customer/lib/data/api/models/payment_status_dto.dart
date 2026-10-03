// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'payment_status_dto.g.dart';

@JsonSerializable()
class PaymentStatusDto {
  const PaymentStatusDto({
    required this.paymentStatus,
  });
  
  factory PaymentStatusDto.fromJson(Map<String, Object?> json) => _$PaymentStatusDtoFromJson(json);
  
  final String paymentStatus;

  Map<String, Object?> toJson() => _$PaymentStatusDtoToJson(this);
}
