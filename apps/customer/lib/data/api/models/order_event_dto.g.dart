// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_event_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderEventDto _$OrderEventDtoFromJson(Map<String, dynamic> json) =>
    OrderEventDto(
      fromStatus: json['fromStatus'] == null
          ? null
          : OrderStatus.fromJson(json['fromStatus'] as String),
      toStatus: OrderStatus.fromJson(json['toStatus'] as String),
      actorRole: json['actorRole'] == null
          ? null
          : Role.fromJson(json['actorRole'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$OrderEventDtoToJson(OrderEventDto instance) =>
    <String, dynamic>{
      'fromStatus': instance.fromStatus,
      'toStatus': instance.toStatus,
      'actorRole': instance.actorRole,
      'note': instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
    };
