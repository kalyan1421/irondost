// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'issue_message_dto.g.dart';

@JsonSerializable()
class IssueMessageDto {
  const IssueMessageDto({
    required this.id,
    required this.fromStaff,
    required this.body,
    required this.createdAt,
  });
  
  factory IssueMessageDto.fromJson(Map<String, Object?> json) => _$IssueMessageDtoFromJson(json);
  
  final String id;
  final bool fromStaff;
  final String body;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$IssueMessageDtoToJson(this);
}
