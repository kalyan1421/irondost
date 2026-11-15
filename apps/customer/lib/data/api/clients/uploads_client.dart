// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/image_upload_dto.dart';

part 'uploads_client.g.dart';

@RestApi()
abstract class UploadsClient {
  factory UploadsClient(Dio dio, {String? baseUrl}) = _UploadsClient;

  @MultiPart()
  @POST('/v1/me/uploads/images')
  Future<ImageUploadDto> customerUploadsControllerUpload({
    @Part(name: 'file') required File file,
  });

  /// A photo of the clothes for a care note, added before the order exists. Same image limits as report photos. It stays free.
  /// until an order is placed with its URL; one photo goes to one order, up to 3 on each order.
  @MultiPart()
  @POST('/v1/me/uploads/care-photos')
  Future<ImageUploadDto> customerUploadsControllerUploadCarePhoto({
    @Part(name: 'file') required File file,
  });
}
