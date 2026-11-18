// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IssueDto _$IssueDtoFromJson(Map<String, dynamic> json) => IssueDto(
  id: json['id'] as String,
  orderId: json['orderId'] as String,
  orderNumber: json['orderNumber'] as String,
  category: IssueCategory.fromJson(json['category'] as String),
  status: IssueStatus.fromJson(json['status'] as String),
  description: json['description'] as String,
  photoUrls: (json['photoUrls'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  firstResponseDueAt: json['firstResponseDueAt'] == null
      ? null
      : DateTime.parse(json['firstResponseDueAt'] as String),
  acknowledgedAt: json['acknowledgedAt'] == null
      ? null
      : DateTime.parse(json['acknowledgedAt'] as String),
  resolvedAt: json['resolvedAt'] == null
      ? null
      : DateTime.parse(json['resolvedAt'] as String),
  resolutionNote: json['resolutionNote'] as String?,
  compensationPaise: json['compensationPaise'] as num?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  messages: (json['messages'] as List<dynamic>)
      .map((e) => IssueMessageDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  handledById: json['handledById'] as String?,
  refundId: json['refundId'] as String?,
);

Map<String, dynamic> _$IssueDtoToJson(IssueDto instance) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'orderNumber': instance.orderNumber,
  'category': instance.category,
  'status': instance.status,
  'description': instance.description,
  'photoUrls': instance.photoUrls,
  'firstResponseDueAt': instance.firstResponseDueAt?.toIso8601String(),
  'acknowledgedAt': instance.acknowledgedAt?.toIso8601String(),
  'resolvedAt': instance.resolvedAt?.toIso8601String(),
  'resolutionNote': instance.resolutionNote,
  'compensationPaise': instance.compensationPaise,
  'handledById': instance.handledById,
  'refundId': instance.refundId,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'messages': instance.messages,
};
