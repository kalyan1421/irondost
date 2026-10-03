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
import 'order_repository.dart';

/// "Pickup booked": shown after an order is placed (and paid, when paid online).
///
/// [initial] is what the API returned when placing, shown at once; the order is then fetched again
/// so the payment status is whatever the server says now.
class OrderConfirmedScreen extends ConsumerWidget {
  const OrderConfirmedScreen({super.key, required this.orderId, this.initial});

  final String orderId;
  final OrderDto? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final order = ref.watch(orderProvider(orderId)).value ?? initial;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: order == null
                    ? const Center(child: CircularProgressIndicator())
                    : Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(IdSpace.s4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: SizedBox(
                                  width: 140,
                                  height: 104,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 96,
                                        height: 96,
                                        decoration: BoxDecoration(color: c.successSoft, shape: BoxShape.circle),
                                        child: ExcludeSemantics(child: Icon(LucideIcons.circleCheck, size: 48, color: c.success)),
                                      ),
                                      const Positioned(right: 4, top: 2, child: Bubble(22)),
                                      const Positioned(right: -6, top: 36, child: Bubble(12)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: IdSpace.s4),
                              Semantics(header: true, liveRegion: true, child: Text('Pickup booked', style: t.headline, textAlign: TextAlign.center)),
                              const SizedBox(height: IdSpace.s3),
                              Text(
                                "${_when(order)} We'll tell you when they're on the way.",
                                style: t.bodyLg.copyWith(color: c.textMuted),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: IdSpace.s6),
                              _Summary(order: order),
                            ],
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s3, IdSpace.s4, IdSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IdButton(label: 'Track order', onPressed: () => context.go(Routes.orders)),
                    const SizedBox(height: IdSpace.s1),
                    IdButton.text(label: 'Back to home', onPressed: () => context.go(Routes.home)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "A partner will come today between 4 and 8 PM."
  static String _when(OrderDto o) {
    final today = istToday();
    final day = o.pickupDate == today ? 'today' : 'on ${dayLong(o.pickupDate)}';
    final window = windowFromLabel(o.pickupSlotLabel).replaceFirst(' – ', ' and ');
    return 'A partner will come $day between $window.';
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.order});
  final OrderDto order;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final pieces = order.items.fold<num>(0, (a, i) => a + i.quantity).toInt();
    final where = [order.pickupAddress.label, order.pickupAddress.area ?? order.pickupAddress.city].join(', ');
    final today = istToday();

    return IdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(order.orderNumber, style: t.orderId)),
              _PaymentChip(order),
            ],
          ),
          const SizedBox(height: IdSpace.s3),
          Container(
            padding: const EdgeInsets.all(IdSpace.s3),
            decoration: BoxDecoration(color: c.surfaceSoft, borderRadius: BorderRadius.circular(IdRadius.md)),
            child: Row(
              children: [
                Expanded(child: _Kv('Pickup', '${dayLong(order.pickupDate, today: today)}, ${windowFromLabel(order.pickupSlotLabel)}')),
                const SizedBox(width: IdSpace.s3),
                Expanded(child: _Kv('Delivery', '${dayLong(order.deliveryDate, today: today)}, ${windowFromLabel(order.deliverySlotLabel)}')),
              ],
            ),
          ),
          const SizedBox(height: IdSpace.s3),
          Text('$pieces ${pieces == 1 ? 'item' : 'items'} · $where', style: t.body.copyWith(color: c.textMuted)),
        ],
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv(this.k, this.v);
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: context.text.caption.copyWith(color: context.colors.textMuted)),
          Text(v, style: context.text.label.copyWith(fontWeight: FontWeight.w600)),
        ],
      );
}

/// "Paid ₹248", "Pay ₹248 at delivery" or "Payment pending".
class _PaymentChip extends StatelessWidget {
  const _PaymentChip(this.order);
  final OrderDto order;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final paid = order.paymentStatus == PaymentStatus.paid;
    final cash = order.paymentMethod == PaymentMethod.cod;
    final (bg, fg, icon, text) = paid
        ? (c.successSoft, c.success, LucideIcons.check, 'Paid ${rupees(order.paidPaise)}')
        : cash
            ? (c.surfaceSoft, c.textMuted, null, 'Pay ${rupees(order.totalPaise)} at delivery')
            : (c.warningSoft, c.warning, null, 'Payment pending');
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(IdRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: IdSize.iconSm, color: fg), const SizedBox(width: IdSpace.s1)],
          Text(text, style: context.text.labelSm.copyWith(color: fg)),
        ],
      ),
    );
  }
}
