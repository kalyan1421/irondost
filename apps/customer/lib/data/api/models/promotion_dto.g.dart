// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromotionDto _$PromotionDtoFromJson(Map<String, dynamic> json) => PromotionDto(
  id: json['id'] as String,
  code: json['code'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  discountType: DiscountType.fromJson(json['discountType'] as String),
  discountValue: json['discountValue'] as num,
  minOrderPaise: json['minOrderPaise'] as num,
  maxDiscountPaise: json['maxDiscountPaise'] as num?,
  perCustomerLimit: json['perCustomerLimit'] as num?,
  validFrom: DateTime.parse(json['validFrom'] as String),
  validTo: DateTime.parse(json['validTo'] as String),
  imageUrl: json['imageUrl'] as String?,
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$PromotionDtoToJson(PromotionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'title': instance.title,
      'description': instance.description,
      'discountType': instance.discountType,
      'discountValue': instance.discountValue,
      'minOrderPaise': instance.minOrderPaise,
      'maxDiscountPaise': instance.maxDiscountPaise,
      'perCustomerLimit': instance.perCustomerLimit,
      'validFrom': instance.validFrom.toIso8601String(),
      'validTo': instance.validTo.toIso8601String(),
      'imageUrl': instance.imageUrl,
      'isActive': instance.isActive,
    };
