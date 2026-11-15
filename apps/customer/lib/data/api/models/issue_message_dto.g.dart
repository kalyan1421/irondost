// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IssueMessageDto _$IssueMessageDtoFromJson(Map<String, dynamic> json) =>
    IssueMessageDto(
      id: json['id'] as String,
      fromStaff: json['fromStaff'] as bool,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$IssueMessageDtoToJson(IssueMessageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fromStaff': instance.fromStaff,
      'body': instance.body,
      'createdAt': instance.createdAt.toIso8601String(),
    };
