// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_line_input.dart';

part 'quote_request_dto.g.dart';

@JsonSerializable()
class QuoteRequestDto {
  const QuoteRequestDto({
    required this.items,
    this.promoCode,
  });
  
  factory QuoteRequestDto.fromJson(Map<String, Object?> json) => _$QuoteRequestDtoFromJson(json);
  
  final List<OrderLineInput> items;
  final String? promoCode;

  Map<String, Object?> toJson() => _$QuoteRequestDtoToJson(this);
}
