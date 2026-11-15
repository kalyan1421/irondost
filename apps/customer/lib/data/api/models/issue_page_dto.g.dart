// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_page_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IssuePageDto _$IssuePageDtoFromJson(Map<String, dynamic> json) => IssuePageDto(
  items: (json['items'] as List<dynamic>)
      .map((e) => IssueDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  page: json['page'] as num,
  pageSize: json['pageSize'] as num,
  total: json['total'] as num,
);

Map<String, dynamic> _$IssuePageDtoToJson(IssuePageDto instance) =>
    <String, dynamic>{
      'items': instance.items,
      'page': instance.page,
      'pageSize': instance.pageSize,
      'total': instance.total,
    };
