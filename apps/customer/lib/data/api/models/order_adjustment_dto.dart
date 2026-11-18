// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'adjustment_line_dto.dart';
import 'adjustment_status.dart';

part 'order_adjustment_dto.g.dart';

@JsonSerializable()
class OrderAdjustmentDto {
  const OrderAdjustmentDto({
    required this.id,
    required this.status,
    required this.reason,
    required this.oldTotalPaise,
    required this.newTotalPaise,
    required this.subtotalPaise,
    required this.discountPaise,
    required this.deliveryFeePaise,
    required this.itemsBefore,
    required this.itemsAfter,
    required this.expiresAt,
    required this.decidedAt,
    required this.createdAt,
  });
  
  factory OrderAdjustmentDto.fromJson(Map<String, Object?> json) => _$OrderAdjustmentDtoFromJson(json);
  
  final String id;
  final AdjustmentStatus status;
  final String reason;
  final num oldTotalPaise;
  final num newTotalPaise;
  final num subtotalPaise;
  final num discountPaise;
  final num deliveryFeePaise;
  final List<AdjustmentLineDto> itemsBefore;
  final List<AdjustmentLineDto> itemsAfter;
  final DateTime expiresAt;
  final DateTime? decidedAt;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$OrderAdjustmentDtoToJson(this);
}
