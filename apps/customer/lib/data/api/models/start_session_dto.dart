// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'client_app.dart';

part 'start_session_dto.g.dart';

@JsonSerializable()
class StartSessionDto {
  const StartSessionDto({
    required this.app,
  });
  
  factory StartSessionDto.fromJson(Map<String, Object?> json) => _$StartSessionDtoFromJson(json);
  
  final ClientApp app;

  Map<String, Object?> toJson() => _$StartSessionDtoToJson(this);
}
