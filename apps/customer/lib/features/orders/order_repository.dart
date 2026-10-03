import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';

/// Placing and reading the signed-in customer's orders.
abstract class OrderRepository {
  /// [idempotencyKey]: one value per checkout attempt. Retrying with the same key returns the order
  /// the first attempt placed instead of placing another.
  Future<OrderDto> place(PlaceOrderDto dto, {required String idempotencyKey});

  Future<OrderDto> get(String id);

  /// An unpaid online order becomes cash on delivery (after a failed or abandoned payment).
  Future<OrderDto> payOnDelivery(String id);
}

class ApiOrderRepository implements OrderRepository {
  ApiOrderRepository(this._api);
  final IronDostApi _api;

  @override
  Future<OrderDto> place(PlaceOrderDto dto, {required String idempotencyKey}) =>
      _guard(() => _api.orders.ordersControllerPlace(body: dto, idempotencyKey: idempotencyKey));

  @override
  Future<OrderDto> get(String id) => _guard(() => _api.orders.ordersControllerGet(id: id));

  @override
  Future<OrderDto> payOnDelivery(String id) => _guard(() => _api.orders.ordersControllerPayOnDelivery(id: id));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiFailure.from(e);
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) => ApiOrderRepository(ref.watch(apiProvider)));

/// One order, fresh from the API. Invalidate it after anything that changes the order (a payment, a cancel).
final orderProvider = FutureProvider.autoDispose.family<OrderDto, String>((ref, id) => ref.watch(orderRepositoryProvider).get(id));
