import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/money.dart';
import '../../core/slots.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/surfaces.dart';
import '../orders/order_repository.dart';

/// "₹180 paid": shown after paying what was due on an existing order. Back returns to the order.
class PaymentReceiptScreen extends ConsumerWidget {
  const PaymentReceiptScreen({super.key, required this.orderId, this.initial});

  final String orderId;
  final OrderDto? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final order = ref.watch(orderProvider(orderId)).value ?? initial;
    final paid = order == null
        ? null
        : rupees(order.paidPaise > 0 ? order.paidPaise : order.totalPaise);
    void back() => context.canPop() ? context.pop() : context.go(Routes.orders);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(IdSpace.s6),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: SizedBox(
                              width: 140,
                              height: 124,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: c.successSoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: ExcludeSemantics(
                                      child: Icon(
                                        LucideIcons.circleCheck,
                                        size: 32,
                                        color: c.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: IdSpace.s6),
                          Semantics(
                            header: true,
                            liveRegion: true,
                            child: Text(
                              paid == null ? 'Paid' : '$paid paid',
                              style: t.headline,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: IdSpace.s3),
                          Text(
                            order == null
                                ? 'Thanks! Your payment is done.'
                                : 'Thanks! Order ${order.orderNumber} is fully paid. Nothing to pay at the door.',
                            style: t.bodyLg.copyWith(color: c.textMuted),
                            textAlign: TextAlign.center,
                          ),
                          if (order != null) ...[
                            const SizedBox(height: IdSpace.s4),
                            IdCard(
                              child: Column(
                                children: [
                                  _Row(
                                    'Order',
                                    Text(order.orderNumber, style: t.orderId),
                                  ),
                                  const SizedBox(height: IdSpace.s2),
                                  _Row(
                                    'Paid online',
                                    Text(
                                      rupees(order.paidPaise),
                                      style: t.label,
                                    ),
                                  ),
                                  const SizedBox(height: IdSpace.s2),
                                  _Row(
                                    'When',
                                    Text(
                                      istDateTimeLabel(DateTime.now()),
                                      style: t.bodyLg,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  IdSpace.s5,
                  IdSpace.s3,
                  IdSpace.s5,
                  IdSpace.s4,
                ),
                child: IdButton(
                  label: 'Back to order',
                  expand: true,
                  onPressed: back,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.k, this.v);
  final String k;
  final Widget v;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        k,
        style: context.text.bodyLg.copyWith(color: context.colors.textMuted),
      ),
      const SizedBox(width: IdSpace.s3),
      Flexible(
        child: Align(alignment: Alignment.centerRight, child: v),
      ),
    ],
  );
}
