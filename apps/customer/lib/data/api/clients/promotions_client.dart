// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/promotion_dto.dart';

part 'promotions_client.g.dart';

@RestApi()
abstract class PromotionsClient {
  factory PromotionsClient(Dio dio, {String? baseUrl}) = _PromotionsClient;

  /// Promotions currently running, for the home screen. Codes are validated when quoting an order.
  @GET('/v1/promotions')
  Future<List<PromotionDto>> promotionsControllerActive();
}
