// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_payment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderPaymentDto _$OrderPaymentDtoFromJson(Map<String, dynamic> json) =>
    OrderPaymentDto(
      id: json['id'] as String,
      provider: PaymentProvider.fromJson(json['provider'] as String),
      amountPaise: json['amountPaise'] as num,
      reference: json['reference'] as String?,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
    );

Map<String, dynamic> _$OrderPaymentDtoToJson(OrderPaymentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'provider': instance.provider,
      'amountPaise': instance.amountPaise,
      'reference': instance.reference,
      'capturedAt': instance.capturedAt.toIso8601String(),
    };
