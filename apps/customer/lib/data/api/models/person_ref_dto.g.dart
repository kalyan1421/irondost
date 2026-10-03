// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person_ref_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonRefDto _$PersonRefDtoFromJson(Map<String, dynamic> json) => PersonRefDto(
  id: json['id'] as String,
  name: json['name'] as String?,
  phone: json['phone'] as String,
);

Map<String, dynamic> _$PersonRefDtoToJson(PersonRefDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
    };
