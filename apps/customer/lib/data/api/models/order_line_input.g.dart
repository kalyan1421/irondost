// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_line_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderLineInput _$OrderLineInputFromJson(Map<String, dynamic> json) =>
    OrderLineInput(
      catalogItemId: json['catalogItemId'] as String,
      quantity: json['quantity'] as num,
    );

Map<String, dynamic> _$OrderLineInputToJson(OrderLineInput instance) =>
    <String, dynamic>{
      'catalogItemId': instance.catalogItemId,
      'quantity': instance.quantity,
    };
