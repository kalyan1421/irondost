// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_config_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicConfigDto _$PublicConfigDtoFromJson(Map<String, dynamic> json) =>
    PublicConfigDto(
      appName: json['appName'] as String,
      supportPhone: json['supportPhone'] as String?,
      supportEmail: json['supportEmail'] as String?,
      minOrderPaise: json['minOrderPaise'] as num,
      deliveryFeePaise: json['deliveryFeePaise'] as num,
      freeDeliveryAbovePaise: json['freeDeliveryAbovePaise'] as num?,
      minTurnaroundHours: json['minTurnaroundHours'] as num,
      maxAdvanceDays: json['maxAdvanceDays'] as num,
      slots: (json['slots'] as List<dynamic>)
          .map((e) => SlotDefinitionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PublicConfigDtoToJson(PublicConfigDto instance) =>
    <String, dynamic>{
      'appName': instance.appName,
      'supportPhone': instance.supportPhone,
      'supportEmail': instance.supportEmail,
      'minOrderPaise': instance.minOrderPaise,
      'deliveryFeePaise': instance.deliveryFeePaise,
      'freeDeliveryAbovePaise': instance.freeDeliveryAbovePaise,
      'minTurnaroundHours': instance.minTurnaroundHours,
      'maxAdvanceDays': instance.maxAdvanceDays,
      'slots': instance.slots,
    };
