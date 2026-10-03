// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_status.dart';
import 'role.dart';

part 'order_event_dto.g.dart';

@JsonSerializable()
class OrderEventDto {
  const OrderEventDto({
    required this.fromStatus,
    required this.toStatus,
    required this.actorRole,
    required this.note,
    required this.createdAt,
  });
  
  factory OrderEventDto.fromJson(Map<String, Object?> json) => _$OrderEventDtoFromJson(json);
  
  final OrderStatus? fromStatus;
  final OrderStatus toStatus;
  final Role? actorRole;
  final String? note;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$OrderEventDtoToJson(this);
}
