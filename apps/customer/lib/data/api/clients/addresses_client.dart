// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/address_dto.dart';
import '../models/create_address_dto.dart';
import '../models/update_address_dto.dart';

part 'addresses_client.g.dart';

@RestApi()
abstract class AddressesClient {
  factory AddressesClient(Dio dio, {String? baseUrl}) = _AddressesClient;

  @GET('/v1/me/addresses')
  Future<List<AddressDto>> addressesControllerList();

  /// Saving is allowed outside the service area; `serviceable` tells the app to show the "not in your area yet" state.
  @POST('/v1/me/addresses')
  Future<AddressDto> addressesControllerCreate({
    @Body() required CreateAddressDto body,
  });

  @PATCH('/v1/me/addresses/{id}')
  Future<AddressDto> addressesControllerUpdate({
    @Path('id') required String id,
    @Body() required UpdateAddressDto body,
  });

  @DELETE('/v1/me/addresses/{id}')
  Future<void> addressesControllerRemove({
    @Path('id') required String id,
  });
}
