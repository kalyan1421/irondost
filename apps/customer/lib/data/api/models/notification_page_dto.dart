// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'notification_dto.dart';

part 'notification_page_dto.g.dart';

@JsonSerializable()
class NotificationPageDto {
  const NotificationPageDto({
    required this.items,
    required this.unread,
    required this.page,
    required this.pageSize,
    required this.total,
  });
  
  factory NotificationPageDto.fromJson(Map<String, Object?> json) => _$NotificationPageDtoFromJson(json);
  
  final List<NotificationDto> items;
  final num unread;
  final num page;
  final num pageSize;
  final num total;

  Map<String, Object?> toJson() => _$NotificationPageDtoToJson(this);
}
