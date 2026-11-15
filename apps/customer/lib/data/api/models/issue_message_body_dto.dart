// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'issue_message_body_dto.g.dart';

@JsonSerializable()
class IssueMessageBodyDto {
  const IssueMessageBodyDto({
    required this.body,
  });
  
  factory IssueMessageBodyDto.fromJson(Map<String, Object?> json) => _$IssueMessageBodyDtoFromJson(json);
  
  final String body;

  Map<String, Object?> toJson() => _$IssueMessageBodyDtoToJson(this);
}
