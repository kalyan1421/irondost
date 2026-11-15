// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/area_interest_dto.dart';
import '../models/register_area_interest_dto.dart';

part 'area_interest_client.g.dart';

@RestApi()
abstract class AreaInterestClient {
  factory AreaInterestClient(Dio dio, {String? baseUrl}) = _AreaInterestClient;

  /// "Tell me when you're here": for a saved address outside the service area. Uses the signed-in customer's own number.
  /// Idempotent: asking again for the same PIN code returns the open request.
  @POST('/v1/me/area-interest')
  Future<AreaInterestDto> areaInterestControllerRegister({
    @Body() required RegisterAreaInterestDto body,
  });
}
