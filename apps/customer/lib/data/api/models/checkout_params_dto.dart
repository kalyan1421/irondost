// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'checkout_params_dto_currency.dart';
import 'checkout_prefill_dto.dart';

part 'checkout_params_dto.g.dart';

@JsonSerializable()
class CheckoutParamsDto {
  const CheckoutParamsDto({
    required this.keyId,
    required this.razorpayOrderId,
    required this.amountPaise,
    required this.currency,
    required this.orderNumber,
    required this.prefill,
  });
  
  factory CheckoutParamsDto.fromJson(Map<String, Object?> json) => _$CheckoutParamsDtoFromJson(json);
  
  final String keyId;
  final String razorpayOrderId;
  final num amountPaise;
  final CheckoutParamsDtoCurrency currency;
  final String orderNumber;
  final CheckoutPrefillDto prefill;

  Map<String, Object?> toJson() => _$CheckoutParamsDtoToJson(this);
}
