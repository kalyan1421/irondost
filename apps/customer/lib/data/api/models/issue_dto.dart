// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'issue_category.dart';
import 'issue_message_dto.dart';
import 'issue_status.dart';

part 'issue_dto.g.dart';

@JsonSerializable()
class IssueDto {
  const IssueDto({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.category,
    required this.status,
    required this.description,
    required this.photoUrls,
    required this.firstResponseDueAt,
    required this.acknowledgedAt,
    required this.resolvedAt,
    required this.resolutionNote,
    required this.compensationPaise,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.handledById,
    this.refundId,
  });
  
  factory IssueDto.fromJson(Map<String, Object?> json) => _$IssueDtoFromJson(json);
  
  final String id;
  final String orderId;
  final String orderNumber;
  final IssueCategory category;
  final IssueStatus status;
  final String description;
  final List<String> photoUrls;
  final DateTime? firstResponseDueAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String? resolutionNote;

  /// Agreed remedy in paise; null until one is recorded.
  final num? compensationPaise;
  final String? handledById;

  /// Staff only.
  final String? refundId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<IssueMessageDto> messages;

  Map<String, Object?> toJson() => _$IssueDtoToJson(this);
}
