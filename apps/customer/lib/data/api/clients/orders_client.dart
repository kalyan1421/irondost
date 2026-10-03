// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/cancel_order_dto.dart';
import '../models/order_dto.dart';
import '../models/order_page_dto.dart';
import '../models/place_order_dto.dart';
import '../models/quote_dto.dart';
import '../models/quote_request_dto.dart';
import '../models/scope.dart';

part 'orders_client.g.dart';

@RestApi()
abstract class OrdersClient {
  factory OrdersClient(Dio dio, {String? baseUrl}) = _OrdersClient;

  /// Server-side price for a basket, including promo validation. Call before placing.
  @POST('/v1/orders/quote')
  Future<QuoteDto> ordersControllerQuote({
    @Body() required QuoteRequestDto body,
  });

  /// [idempotencyKey] - One value per checkout attempt (a UUID). Retrying with the same key returns the order the first attempt placed, with the Idempotent-Replayed: true header, instead of placing another.
  @POST('/v1/orders')
  Future<OrderDto> ordersControllerPlace({
    @Body() required PlaceOrderDto body,
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  /// [scope] - active = not yet delivered or cancelled; past = delivered or cancelled; omit for all
  @GET('/v1/orders')
  Future<OrderPageDto> ordersControllerList({
    @Query('scope') Scope? scope,
    @Query('page') num? page = 1,
    @Query('pageSize') num? pageSize = 20,
  });

  @GET('/v1/orders/{id}')
  Future<OrderDto> ordersControllerGet({
    @Path('id') required String id,
  });

  /// For an online order that has not been paid (a failed or abandoned payment): the partner collects the amount at delivery.
  @POST('/v1/orders/{id}/pay-on-delivery')
  Future<OrderDto> ordersControllerPayOnDelivery({
    @Path('id') required String id,
  });

  /// Allowed until the clothes are picked up.
  @POST('/v1/orders/{id}/cancel')
  Future<OrderDto> ordersControllerCancel({
    @Path('id') required String id,
    @Body() required CancelOrderDto body,
  });
}
