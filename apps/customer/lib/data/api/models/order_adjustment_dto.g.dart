// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_adjustment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderAdjustmentDto _$OrderAdjustmentDtoFromJson(Map<String, dynamic> json) =>
    OrderAdjustmentDto(
      id: json['id'] as String,
      status: AdjustmentStatus.fromJson(json['status'] as String),
      reason: json['reason'] as String,
      oldTotalPaise: json['oldTotalPaise'] as num,
      newTotalPaise: json['newTotalPaise'] as num,
      subtotalPaise: json['subtotalPaise'] as num,
      discountPaise: json['discountPaise'] as num,
      deliveryFeePaise: json['deliveryFeePaise'] as num,
      itemsBefore: (json['itemsBefore'] as List<dynamic>)
          .map((e) => AdjustmentLineDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemsAfter: (json['itemsAfter'] as List<dynamic>)
          .map((e) => AdjustmentLineDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      decidedAt: json['decidedAt'] == null
          ? null
          : DateTime.parse(json['decidedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$OrderAdjustmentDtoToJson(OrderAdjustmentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'reason': instance.reason,
      'oldTotalPaise': instance.oldTotalPaise,
      'newTotalPaise': instance.newTotalPaise,
      'subtotalPaise': instance.subtotalPaise,
      'discountPaise': instance.discountPaise,
      'deliveryFeePaise': instance.deliveryFeePaise,
      'itemsBefore': instance.itemsBefore,
      'itemsAfter': instance.itemsAfter,
      'expiresAt': instance.expiresAt.toIso8601String(),
      'decidedAt': instance.decidedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
