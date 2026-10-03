// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'verify_checkout_dto.g.dart';

@JsonSerializable()
class VerifyCheckoutDto {
  const VerifyCheckoutDto({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });
  
  factory VerifyCheckoutDto.fromJson(Map<String, Object?> json) => _$VerifyCheckoutDtoFromJson(json);
  
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  Map<String, Object?> toJson() => _$VerifyCheckoutDtoToJson(this);
}
