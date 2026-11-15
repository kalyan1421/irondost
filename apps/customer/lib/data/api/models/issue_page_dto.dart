// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'issue_dto.dart';

part 'issue_page_dto.g.dart';

@JsonSerializable()
class IssuePageDto {
  const IssuePageDto({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });
  
  factory IssuePageDto.fromJson(Map<String, Object?> json) => _$IssuePageDtoFromJson(json);
  
  final List<IssueDto> items;
  final num page;
  final num pageSize;
  final num total;

  Map<String, Object?> toJson() => _$IssuePageDtoToJson(this);
}
