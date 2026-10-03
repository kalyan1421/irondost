// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/public_config_dto.dart';
import '../models/service_area_check_dto.dart';

part 'config_client.g.dart';

@RestApi()
abstract class ConfigClient {
  factory ConfigClient(Dio dio, {String? baseUrl}) = _ConfigClient;

  @GET('/v1/config')
  Future<PublicConfigDto> publicConfigControllerGet();

  /// Whether IronDost serves a map pin and/or PIN code. Public, so the website can ask before sign-up.
  @GET('/v1/service-area/check')
  Future<ServiceAreaCheckDto> serviceAreaControllerCheck({
    @Query('latitude') num? latitude,
    @Query('longitude') num? longitude,
    @Query('pincode') String? pincode,
  });
}
