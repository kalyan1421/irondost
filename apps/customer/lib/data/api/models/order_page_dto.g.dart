// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_page_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderPageDto _$OrderPageDtoFromJson(Map<String, dynamic> json) => OrderPageDto(
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  page: json['page'] as num,
  pageSize: json['pageSize'] as num,
  total: json['total'] as num,
);

Map<String, dynamic> _$OrderPageDtoToJson(OrderPageDto instance) =>
    <String, dynamic>{
      'items': instance.items,
      'page': instance.page,
      'pageSize': instance.pageSize,
      'total': instance.total,
    };
