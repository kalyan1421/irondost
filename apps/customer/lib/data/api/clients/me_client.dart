// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/me_dto.dart';
import '../models/notification_page_dto.dart';
import '../models/register_device_dto.dart';
import '../models/remove_device_dto.dart';
import '../models/update_me_dto.dart';

part 'me_client.g.dart';

@RestApi()
abstract class MeClient {
  factory MeClient(Dio dio, {String? baseUrl}) = _MeClient;

  @GET('/v1/me')
  Future<MeDto> usersControllerMe();

  @PATCH('/v1/me')
  Future<MeDto> usersControllerUpdate({
    @Body() required UpdateMeDto body,
  });

  @DELETE('/v1/me')
  Future<void> usersControllerDeleteAccount();

  @POST('/v1/me/devices')
  Future<void> usersControllerRegisterDevice({
    @Body() required RegisterDeviceDto body,
  });

  /// Call on sign-out so the device stops receiving this user's pushes.
  @POST('/v1/me/devices/remove')
  Future<void> usersControllerRemoveDevice({
    @Body() required RemoveDeviceDto body,
  });

  @GET('/v1/me/notifications')
  Future<NotificationPageDto> notificationsControllerList({
    @Query('page') num? page = 1,
    @Query('pageSize') num? pageSize = 20,
  });

  @POST('/v1/me/notifications/{id}/read')
  Future<void> notificationsControllerRead({
    @Path('id') required String id,
  });

  @POST('/v1/me/notifications/read-all')
  Future<void> notificationsControllerReadAll();
}
