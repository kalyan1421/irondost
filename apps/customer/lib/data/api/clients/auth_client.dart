// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/start_session_dto.dart';
import '../models/user_dto.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  /// Exchange a verified Firebase phone-OTP token for a user record.
  @POST('/v1/auth/session')
  Future<UserDto> authControllerSession({
    @Body() required StartSessionDto body,
  });
}
