// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_params_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckoutParamsDto _$CheckoutParamsDtoFromJson(Map<String, dynamic> json) =>
    CheckoutParamsDto(
      keyId: json['keyId'] as String,
      razorpayOrderId: json['razorpayOrderId'] as String,
      amountPaise: json['amountPaise'] as num,
      currency: CheckoutParamsDtoCurrency.fromJson(json['currency'] as String),
      orderNumber: json['orderNumber'] as String,
      prefill: CheckoutPrefillDto.fromJson(
        json['prefill'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$CheckoutParamsDtoToJson(CheckoutParamsDto instance) =>
    <String, dynamic>{
      'keyId': instance.keyId,
      'razorpayOrderId': instance.razorpayOrderId,
      'amountPaise': instance.amountPaise,
      'currency': instance.currency,
      'orderNumber': instance.orderNumber,
      'prefill': instance.prefill,
    };
