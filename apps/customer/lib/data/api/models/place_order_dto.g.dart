// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_order_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceOrderDto _$PlaceOrderDtoFromJson(Map<String, dynamic> json) =>
    PlaceOrderDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderLineInput.fromJson(e as Map<String, dynamic>))
          .toList(),
      pickupDate: json['pickupDate'] as String,
      pickupSlot: TimeSlot.fromJson(json['pickupSlot'] as String),
      deliveryDate: json['deliveryDate'] as String,
      deliverySlot: TimeSlot.fromJson(json['deliverySlot'] as String),
      pickupAddressId: json['pickupAddressId'] as String,
      paymentMethod: PaymentMethod.fromJson(json['paymentMethod'] as String),
      promoCode: json['promoCode'] as String?,
      deliveryAddressId: json['deliveryAddressId'] as String?,
      instructions: json['instructions'] as String?,
    );

Map<String, dynamic> _$PlaceOrderDtoToJson(PlaceOrderDto instance) =>
    <String, dynamic>{
      'items': instance.items,
      'promoCode': instance.promoCode,
      'pickupDate': instance.pickupDate,
      'pickupSlot': instance.pickupSlot,
      'deliveryDate': instance.deliveryDate,
      'deliverySlot': instance.deliverySlot,
      'pickupAddressId': instance.pickupAddressId,
      'deliveryAddressId': instance.deliveryAddressId,
      'paymentMethod': instance.paymentMethod,
      'instructions': instance.instructions,
    };
