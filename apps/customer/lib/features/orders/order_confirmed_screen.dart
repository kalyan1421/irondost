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
import '../../design/widgets/numbered_steps.dart';
import '../../design/widgets/surfaces.dart';
import '../push/push_handler.dart';
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
                          padding: const EdgeInsets.all(IdSpace.s5),
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
                                        decoration: BoxDecoration(
                                          color: c.successSoft,
                                          shape: BoxShape.circle,
                                        ),
                                        child: ExcludeSemantics(
                                          child: Icon(
                                            LucideIcons.circleCheck,
                                            size: 48,
                                            color: c.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: IdSpace.s4),
                              Semantics(
                                header: true,
                                liveRegion: true,
                                child: Text(
                                  'Pickup booked',
                                  style: t.headline,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: IdSpace.s3),
                              Text(
                                "${_when(order)} We'll tell you when they're on the way.",
                                style: t.bodyLg.copyWith(color: c.textMuted),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: IdSpace.s6),
                              _Summary(order: order),
                              const SizedBox(height: IdSpace.s6),
                              const _NextSteps(),
                            ],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IdButton(
                      label: 'Track order',
                      onPressed: () => _leave(context, ref, () {
                        // The Orders tab underneath, so Back from the order lands somewhere sensible.
                        context.go(Routes.orders);
                        context.push(Routes.order(orderId), extra: order);
                      }),
                    ),
                    const SizedBox(height: IdSpace.s1),
                    IdButton.text(
                      label: 'Back to home',
                      onPressed: () =>
                          _leave(context, ref, () => context.go(Routes.home)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Leaves the confirmation. The first time, it offers notifications on the way out.
  static Future<void> _leave(
    BuildContext context,
    WidgetRef ref,
    VoidCallback go,
  ) async {
    if (await ref.read(pushOfferProvider).shouldOffer() && context.mounted) {
      await context.push(Routes.notificationPermission);
    }
    if (context.mounted) go();
  }

  /// "A partner will come today between 4 and 8 PM."
  static String _when(OrderDto o) {
    final today = istToday();
    final day = o.pickupDate == today ? 'today' : 'on ${dayLong(o.pickupDate)}';
    final window = windowFromLabel(o.pickupSlotLabel)
        .replaceFirst(' – ', ' and ');
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
    final where = [
      order.pickupAddress.label,
      order.pickupAddress.area ?? order.pickupAddress.city,
    ].join(', ');
    final today = istToday();

    return IdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: IdSpace.s3,
            runSpacing: IdSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(order.orderNumber, style: t.orderId),
              _PaymentChip(order),
            ],
          ),
          const SizedBox(height: IdSpace.s3),
          Container(
            padding: const EdgeInsets.all(IdSpace.s3),
            decoration: BoxDecoration(
              color: c.surfaceSoft,
              borderRadius: BorderRadius.circular(IdRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Kv(
                  'Pickup',
                  '${dayLong(order.pickupDate, today: today)}, ${windowFromLabel(order.pickupSlotLabel)}',
                ),
                const SizedBox(height: IdSpace.s3),
                _Kv(
                  'Delivery',
                  '${dayLong(order.deliveryDate, today: today)}, ${windowFromLabel(order.deliverySlotLabel)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: IdSpace.s3),
          Text(
            '$pieces ${pieces == 1 ? 'item' : 'items'} · $where',
            style: t.body.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

/// What the customer can expect, in the order the tracker will show it. Every line restates
/// something the app already tells them elsewhere (the count is confirmed at pickup, the tracker
/// has an Ironing step, the delivery window was chosen), so this adds no new promise.
class _NextSteps extends StatelessWidget {
  const _NextSteps();

  static const _steps = [
    ('Collected and counted', 'Your partner counts your clothes at pickup.'),
    ('Ironed at our workshop', 'Track each step from the Orders tab.'),
    ('Brought back to you', 'A partner delivers in the window you chose.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('What happens next', style: context.text.title),
        ),
        const SizedBox(height: IdSpace.s2),
        const NumberedSteps(steps: _steps),
      ],
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
      Text(
        k,
        style: context.text.caption.copyWith(color: context.colors.textMuted),
      ),
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
        ? (
            c.successSoft,
            c.success,
            LucideIcons.check,
            'Paid ${rupees(order.paidPaise)}',
          )
        : cash
        ? (
            c.surfaceSoft,
            c.textMuted,
            null,
            'Pay ${rupees(order.totalPaise)} at delivery',
          )
        : (c.warningSoft, c.warning, null, 'Payment pending');
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(
        horizontal: IdSpace.s2,
        vertical: IdSpace.s1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(IdRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: IdSize.iconSm, color: fg),
            const SizedBox(width: IdSpace.s1),
          ],
          Flexible(
            child: Text(text, style: context.text.labelSm.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}
