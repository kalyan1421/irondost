import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';

/// The API side of paying online. The server creates the Razorpay order and checks the signature;
/// the app never decides that a payment succeeded.
abstract class PaymentRepository {
  /// Razorpay Checkout parameters for whatever is still due on the order.
  Future<CheckoutParamsDto> start(String orderId);

  /// Checks the signature Razorpay returned and records the payment.
  Future<PaymentStatusDto> verify({required String razorpayOrderId, required String razorpayPaymentId, required String razorpaySignature});
}

class ApiPaymentRepository implements PaymentRepository {
  ApiPaymentRepository(this._api);
  final IronDostApi _api;

  @override
  Future<CheckoutParamsDto> start(String orderId) => _guard(() => _api.payments.paymentsControllerCreateRazorpayOrder(id: orderId));

  @override
  Future<PaymentStatusDto> verify({required String razorpayOrderId, required String razorpayPaymentId, required String razorpaySignature}) => _guard(
        () => _api.payments.paymentsControllerVerify(
          body: VerifyCheckoutDto(razorpayOrderId: razorpayOrderId, razorpayPaymentId: razorpayPaymentId, razorpaySignature: razorpaySignature),
        ),
      );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiFailure.from(e);
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) => ApiPaymentRepository(ref.watch(apiProvider)));
