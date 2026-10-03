// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/app_version_dto.dart';
import '../models/client_app.dart';
import '../models/device_platform.dart';
import '../models/upsert_app_version_dto.dart';

part 'app_versions_client.g.dart';

@RestApi()
abstract class AppVersionsClient {
  factory AppVersionsClient(Dio dio, {String? baseUrl}) = _AppVersionsClient;

  /// Apps call this on launch: below minVersion → force update; below latestVersion → suggest update.
  @GET('/v1/app-versions')
  Future<dynamic> appVersionsControllerGet({
    @Query('app') required ClientApp app,
    @Query('platform') required DevicePlatform platform,
  });

  @PUT('/v1/app-versions')
  Future<AppVersionDto> appVersionsControllerUpsert({
    @Body() required UpsertAppVersionDto body,
  });
}
