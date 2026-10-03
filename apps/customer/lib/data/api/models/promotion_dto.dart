// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'discount_type.dart';

part 'promotion_dto.g.dart';

@JsonSerializable()
class PromotionDto {
  const PromotionDto({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderPaise,
    required this.maxDiscountPaise,
    required this.perCustomerLimit,
    required this.validFrom,
    required this.validTo,
    required this.imageUrl,
    required this.isActive,
  });
  
  factory PromotionDto.fromJson(Map<String, Object?> json) => _$PromotionDtoFromJson(json);
  
  final String id;
  final String code;
  final String title;
  final String? description;
  final DiscountType discountType;
  final num discountValue;
  final num minOrderPaise;
  final num? maxDiscountPaise;
  final num? perCustomerLimit;
  final DateTime validFrom;
  final DateTime validTo;
  final String? imageUrl;
  final bool isActive;

  Map<String, Object?> toJson() => _$PromotionDtoToJson(this);
}
