// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/banner_dto.dart';

part 'banners_client.g.dart';

@RestApi()
abstract class BannersClient {
  factory BannersClient(Dio dio, {String? baseUrl}) = _BannersClient;

  @GET('/v1/banners')
  Future<List<BannerDto>> bannersControllerActive();
}
