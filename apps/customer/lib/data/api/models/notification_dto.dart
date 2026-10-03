// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'notification_dto.g.dart';

@JsonSerializable()
class NotificationDto {
  const NotificationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });
  
  factory NotificationDto.fromJson(Map<String, Object?> json) => _$NotificationDtoFromJson(json);
  
  final String id;
  final String type;
  final String title;
  final String body;
  final dynamic data;
  final DateTime? readAt;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$NotificationDtoToJson(this);
}
