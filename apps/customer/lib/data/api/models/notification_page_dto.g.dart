// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_page_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationPageDto _$NotificationPageDtoFromJson(Map<String, dynamic> json) =>
    NotificationPageDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => NotificationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      unread: json['unread'] as num,
      page: json['page'] as num,
      pageSize: json['pageSize'] as num,
      total: json['total'] as num,
    );

Map<String, dynamic> _$NotificationPageDtoToJson(
  NotificationPageDto instance,
) => <String, dynamic>{
  'items': instance.items,
  'unread': instance.unread,
  'page': instance.page,
  'pageSize': instance.pageSize,
  'total': instance.total,
};
