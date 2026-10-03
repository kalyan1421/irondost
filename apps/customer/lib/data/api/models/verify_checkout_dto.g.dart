// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_checkout_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifyCheckoutDto _$VerifyCheckoutDtoFromJson(Map<String, dynamic> json) =>
    VerifyCheckoutDto(
      razorpayOrderId: json['razorpayOrderId'] as String,
      razorpayPaymentId: json['razorpayPaymentId'] as String,
      razorpaySignature: json['razorpaySignature'] as String,
    );

Map<String, dynamic> _$VerifyCheckoutDtoToJson(VerifyCheckoutDto instance) =>
    <String, dynamic>{
      'razorpayOrderId': instance.razorpayOrderId,
      'razorpayPaymentId': instance.razorpayPaymentId,
      'razorpaySignature': instance.razorpaySignature,
    };
