// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'refund_method.dart';
import 'refund_status.dart';
import 'staff_ref_dto.dart';

part 'refund_dto.g.dart';

@JsonSerializable()
class RefundDto {
  const RefundDto({
    required this.id,
    required this.amountPaise,
    required this.method,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.processedAt,
    required this.failureReason,
    this.createdBy,
  });
  
  factory RefundDto.fromJson(Map<String, Object?> json) => _$RefundDtoFromJson(json);
  
  final String id;
  final num amountPaise;
  final RefundMethod method;

  /// PENDING: Razorpay is still sending it. Only PENDING and PROCESSED count toward refundedPaise.
  final RefundStatus status;

  /// Staff note to the customer.
  final String note;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? failureReason;

  /// Staff member who issued it. Admin view only.
  final StaffRefDto? createdBy;

  Map<String, Object?> toJson() => _$RefundDtoToJson(this);
}
