// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_dto.dart';

part 'order_page_dto.g.dart';

@JsonSerializable()
class OrderPageDto {
  const OrderPageDto({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });
  
  factory OrderPageDto.fromJson(Map<String, Object?> json) => _$OrderPageDtoFromJson(json);
  
  final List<OrderDto> items;
  final num page;
  final num pageSize;
  final num total;

  Map<String, Object?> toJson() => _$OrderPageDtoToJson(this);
}
