// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/checkout_params_dto.dart';
import '../models/payment_status_dto.dart';
import '../models/verify_checkout_dto.dart';

part 'payments_client.g.dart';

@RestApi()
abstract class PaymentsClient {
  factory PaymentsClient(Dio dio, {String? baseUrl}) = _PaymentsClient;

  /// Returns the parameters for Razorpay Checkout on the device.
  @POST('/v1/orders/{id}/payments/razorpay')
  Future<CheckoutParamsDto> paymentsControllerCreateRazorpayOrder({
    @Path('id') required String id,
  });

  @POST('/v1/payments/razorpay/verify')
  Future<PaymentStatusDto> paymentsControllerVerify({
    @Body() required VerifyCheckoutDto body,
  });
}
