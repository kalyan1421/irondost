// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_prefill_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckoutPrefillDto _$CheckoutPrefillDtoFromJson(Map<String, dynamic> json) =>
    CheckoutPrefillDto(
      name: json['name'] as String?,
      contact: json['contact'] as String,
      email: json['email'] as String?,
    );

Map<String, dynamic> _$CheckoutPrefillDtoToJson(CheckoutPrefillDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'contact': instance.contact,
      'email': instance.email,
    };
