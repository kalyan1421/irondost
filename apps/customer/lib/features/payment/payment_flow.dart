import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../data/api_client.dart';

/// What happens once an order exists: an online order goes to payment, cash on delivery straight to
/// the confirmation. `go` (not `push`) because the checkout is over; there is nothing to come back to.
Future<void> continueAfterPlacing(BuildContext context, WidgetRef ref, OrderDto order) async {
  if (order.paymentMethod == PaymentMethod.online && order.amountDuePaise > 0) {
    context.go(Routes.pay(order.id), extra: order);
  } else {
    context.go(Routes.confirmed(order.id), extra: order);
  }
}
