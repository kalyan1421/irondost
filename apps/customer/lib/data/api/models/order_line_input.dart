// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'order_line_input.g.dart';

@JsonSerializable()
class OrderLineInput {
  const OrderLineInput({
    required this.catalogItemId,
    required this.quantity,
  });
  
  factory OrderLineInput.fromJson(Map<String, Object?> json) => _$OrderLineInputFromJson(json);
  
  final String catalogItemId;
  final num quantity;

  Map<String, Object?> toJson() => _$OrderLineInputToJson(this);
}
