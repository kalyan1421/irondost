// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/catalog_category_dto.dart';

part 'catalog_client.g.dart';

@RestApi()
abstract class CatalogClient {
  factory CatalogClient(Dio dio, {String? baseUrl}) = _CatalogClient;

  /// Active categories and items with prices, for the customer app and website.
  @GET('/v1/catalog')
  Future<List<CatalogCategoryDto>> catalogControllerList();
}
