// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refund_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefundDto _$RefundDtoFromJson(Map<String, dynamic> json) => RefundDto(
  id: json['id'] as String,
  amountPaise: json['amountPaise'] as num,
  method: RefundMethod.fromJson(json['method'] as String),
  status: RefundStatus.fromJson(json['status'] as String),
  note: json['note'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  processedAt: json['processedAt'] == null
      ? null
      : DateTime.parse(json['processedAt'] as String),
  failureReason: json['failureReason'] as String?,
  createdBy: json['createdBy'] == null
      ? null
      : StaffRefDto.fromJson(json['createdBy'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RefundDtoToJson(RefundDto instance) => <String, dynamic>{
  'id': instance.id,
  'amountPaise': instance.amountPaise,
  'method': instance.method,
  'status': instance.status,
  'note': instance.note,
  'createdAt': instance.createdAt.toIso8601String(),
  'processedAt': instance.processedAt?.toIso8601String(),
  'failureReason': instance.failureReason,
  'createdBy': instance.createdBy,
};
