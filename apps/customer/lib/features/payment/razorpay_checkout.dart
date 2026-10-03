import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../data/api_client.dart';
import '../../design/theme.dart';

/// How a Razorpay Checkout session ended, as far as the device knows. Only the server's signature
/// check turns [CheckoutPaid] into a recorded payment.
sealed class CheckoutResult {
  const CheckoutResult();
}

/// Razorpay says it was paid. These three values go to the API to be verified.
class CheckoutPaid extends CheckoutResult {
  const CheckoutPaid({required this.paymentId, required this.orderId, required this.signature});
  final String paymentId;
  final String orderId;
  final String signature;
}

/// The customer closed the payment window.
class CheckoutCancelled extends CheckoutResult {
  const CheckoutCancelled();
}

/// The bank or Razorpay declined it, or the window could not open.
class CheckoutFailed extends CheckoutResult {
  const CheckoutFailed({required this.code, this.message});
  final int code;
  final String? message;
}

/// The customer went to a wallet app. The result reaches the server by webhook, not through the device.
class CheckoutExternalWallet extends CheckoutResult {
  const CheckoutExternalWallet(this.walletName);
  final String? walletName;
}

/// Opens Razorpay Checkout for an order the server has already created.
abstract class RazorpayCheckout {
  Future<CheckoutResult> open(CheckoutParamsDto params);
}

class SdkRazorpayCheckout implements RazorpayCheckout {
  const SdkRazorpayCheckout({required this.brandColor});

  /// The checkout window's accent, from the theme.
  final Color brandColor;

  @override
  Future<CheckoutResult> open(CheckoutParamsDto params) {
    final razorpay = Razorpay();
    final done = Completer<CheckoutResult>();
    void finish(CheckoutResult result) {
      if (!done.isCompleted) done.complete(result);
    }

    razorpay
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
        final paymentId = r.paymentId;
        final orderId = r.orderId;
        final signature = r.signature;
        finish(
          paymentId == null || orderId == null || signature == null
              ? const CheckoutFailed(code: Razorpay.UNKNOWN_ERROR, message: 'Razorpay did not return the payment details.')
              : CheckoutPaid(paymentId: paymentId, orderId: orderId, signature: signature),
        );
      })
      ..on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
        finish(r.code == Razorpay.PAYMENT_CANCELLED ? const CheckoutCancelled() : CheckoutFailed(code: r.code ?? Razorpay.UNKNOWN_ERROR, message: r.message));
      })
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) => finish(CheckoutExternalWallet(r.walletName)));

    final options = <String, Object?>{
      'key': params.keyId,
      'order_id': params.razorpayOrderId,
      'amount': params.amountPaise,
      'currency': params.currency.json,
      'name': 'IronDost',
      'description': 'Order ${params.orderNumber}',
      'prefill': {
        'contact': params.prefill.contact,
        if (params.prefill.name != null) 'name': params.prefill.name,
        if (params.prefill.email != null) 'email': params.prefill.email,
      },
      'theme': {'color': _hex(brandColor)},
      'timeout': 600,
    };
    razorpay.open(options.cast<String, dynamic>());
    return done.future.whenComplete(razorpay.clear);
  }

  static String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

final razorpayCheckoutProvider = Provider<RazorpayCheckout>((ref) => SdkRazorpayCheckout(brandColor: IdColors.light.primary));
