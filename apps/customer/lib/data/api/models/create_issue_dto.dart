// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'issue_category.dart';

part 'create_issue_dto.g.dart';

@JsonSerializable()
class CreateIssueDto {
  const CreateIssueDto({
    required this.category,
    required this.description,
    this.photoUrls,
  });
  
  factory CreateIssueDto.fromJson(Map<String, Object?> json) => _$CreateIssueDtoFromJson(json);
  
  final IssueCategory category;
  final String description;
  final List<String>? photoUrls;

  Map<String, Object?> toJson() => _$CreateIssueDtoToJson(this);
}
