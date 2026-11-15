import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/money.dart';
import '../../core/order_text.dart';
import '../../core/slots.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/state_view.dart';
import '../../design/widgets/surfaces.dart';
import '../orders/order_repository.dart';

/// Receipt facts always come from a fresh server-confirmed order and its captured payments.
class PaymentReceiptScreen extends ConsumerWidget {
  const PaymentReceiptScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderProvider(orderId));
    final order = async.value;
    final t = context.text;
    final c = context.colors;
    void back() => context.canPop() ? context.pop() : context.go(Routes.order(orderId));
    final backButton = IdButton.outline(label: 'Back to order', onPressed: back, expand: true);
    Widget body;
    if (async.hasError) {
      body = StateView(icon: LucideIcons.circleAlert, title: "Couldn't confirm this payment",
        body: 'Check the order before trying another payment.',
        primary: IdButton(label: 'Check again', onPressed: () => ref.invalidate(orderProvider(orderId))), secondary: backButton);
    } else if (order == null || async.isLoading) {
      body = const Center(child: CircularProgressIndicator(semanticsLabel: 'Checking payment'));
    } else if (order.paymentStatus != PaymentStatus.paid || order.amountDuePaise > 0) {
      body = StateView(icon: LucideIcons.clock, title: 'Check your order payment',
        body: order.paymentStatus == PaymentStatus.refunded ? 'This order has refund activity. Open the order for the current status.'
          : '${rupees(order.amountDuePaise)} is still due. This page does not confirm a completed payment.',
        primary: backButton);
    } else {
      final payments = [...?order.payments]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
      body = SafeArea(child: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(IdSpace.s5), children: [
          Icon(LucideIcons.circleCheck, color: c.success, size: 48),
          const SizedBox(height: IdSpace.s5),
          Semantics(header: true, liveRegion: true, child: Text(
            payments.isEmpty ? 'Order fully paid' : '${rupees(payments.last.amountPaise)} paid',
            style: t.headline, textAlign: TextAlign.center)),
          const SizedBox(height: IdSpace.s3),
          Text('Thanks! Order ${order.orderNumber} is fully paid. Nothing to pay at the door.', style: t.bodyLg, textAlign: TextAlign.center),
          const SizedBox(height: IdSpace.s5),
          IdCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(order.orderNumber, style: t.orderId),
            Text('Total received: ${rupees(order.paidPaise)}', style: t.title),
            Text(paidHow(order), style: t.body),
          ])),
          for (final p in payments) ...[
            const SizedBox(height: IdSpace.s3),
            IdCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${rupees(p.amountPaise)} · ${p.provider == PaymentProvider.cash ? 'Cash' : 'Online'}', style: t.title),
              Text(istDateTimeLabel(p.capturedAt), style: t.body),
              if (p.reference != null) SelectableText(p.reference!, style: t.caption),
            ])),
          ],
        ])),
        Padding(padding: const EdgeInsets.all(IdSpace.s5), child: backButton),
      ]));
    }
    return Scaffold(appBar: AppBar(leading: BackButton(onPressed: back), title: const Text('Payment receipt')), body: body);
  }
}
