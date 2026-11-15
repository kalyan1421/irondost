// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_issue_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateIssueDto _$CreateIssueDtoFromJson(Map<String, dynamic> json) =>
    CreateIssueDto(
      category: IssueCategory.fromJson(json['category'] as String),
      description: json['description'] as String,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CreateIssueDtoToJson(CreateIssueDto instance) =>
    <String, dynamic>{
      'category': instance.category,
      'description': instance.description,
      'photoUrls': instance.photoUrls,
    };
