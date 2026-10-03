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
import '../../design/widgets/surfaces.dart';
import 'order_repository.dart';

/// "Items and bill": what was counted, what it costs, what has been paid and what is still due.
class OrderBillScreen extends ConsumerWidget {
  const OrderBillScreen({super.key, required this.orderId, this.initial});

  final String orderId;
  final OrderDto? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderProvider(orderId)).value ?? initial;
    final c = context.colors;
    final t = context.text;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.orders)),
        title: Text('Items and bill', style: t.titleLg),
      ),
      body: order == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s4, IdSpace.s4, IdSpace.s6),
              children: [
                _Head(order),
                const SizedBox(height: IdSpace.s4),
                IdCard(
                  padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s1, IdSpace.s4, IdSpace.s1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: IdSpace.s3, bottom: IdSpace.s1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Semantics(header: true, child: Text('Items', style: t.title)),
                            if (order.pickedUpAt != null) Text('Counted at pickup', style: t.caption.copyWith(color: c.textMuted)),
                          ],
                        ),
                      ),
                      for (final (i, item) in order.items.indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: IdSpace.s3),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: t.title),
                                    Text('${item.quantity.toInt()} × ${rupees(item.unitPricePaise)}', style: t.caption.copyWith(color: c.textMuted)),
                                  ],
                                ),
                              ),
                              Text(rupees(item.lineTotalPaise), style: t.label.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: IdSpace.s4),
                _Bill(order),
              ],
            ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.order);
  final OrderDto order;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final paid = order.paymentStatus == PaymentStatus.paid;
    final dates = [
      if (order.pickedUpAt != null) 'Picked up ${istDayLabel(order.pickedUpAt!)}',
      if (order.deliveredAt != null) 'Delivered ${istDayLabel(order.deliveredAt!)}' else 'Delivery ${dayLong(order.deliveryDate)}',
    ].join(' · ');
    return IdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(order.orderNumber, style: t.orderId)),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: paid ? c.successSoft : c.warningSoft, borderRadius: BorderRadius.circular(IdRadius.full)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (paid) ...[Icon(LucideIcons.check, size: IdSize.iconSm, color: c.success), const SizedBox(width: IdSpace.s1)],
                    Text(paid ? 'Paid' : (order.amountDuePaise > 0 ? '${rupees(order.amountDuePaise)} due' : 'Unpaid'), style: t.labelSm.copyWith(color: paid ? c.success : c.warning)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: IdSpace.s1),
          Text(dates, style: t.caption.copyWith(color: c.textMuted)),
        ],
      ),
    );
  }
}

class _Bill extends StatelessWidget {
  const _Bill(this.order);
  final OrderDto order;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final figures = [const FontFeature.tabularFigures()];
    Widget row(String k, String v, {Color? color, FontWeight? weight}) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(k, style: t.bodyLg.copyWith(color: color, fontWeight: weight))),
            const SizedBox(width: IdSpace.s3),
            Text(v, style: t.bodyLg.copyWith(color: color, fontWeight: weight, fontFeatures: figures)),
          ],
        );
    final how = paidHow(order);
    return IdCard(
      child: Column(
        children: [
          row('Items (${pieceCount(order)})', rupees(order.subtotalPaise)),
          if (order.discountPaise > 0) ...[
            const SizedBox(height: 10),
            row(order.promoCode ?? 'Discount', '−${rupees(order.discountPaise)}', color: c.success, weight: FontWeight.w600),
          ],
          const SizedBox(height: 10),
          row('Pickup & delivery', order.deliveryFeePaise == 0 ? 'Free' : rupees(order.deliveryFeePaise), color: c.textMuted),
          const SizedBox(height: IdSpace.s3),
          Container(
            padding: const EdgeInsets.only(top: IdSpace.s3),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderStrong))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: t.titleLg),
                    Text(rupees(order.totalPaise), style: t.titleLg.copyWith(fontFeatures: figures)),
                  ],
                ),
                if (order.paidPaise > 0) ...[const SizedBox(height: 10), row(how, rupees(order.paidPaise), color: c.success, weight: FontWeight.w600)],
                if (order.refundedPaise > 0) ...[const SizedBox(height: 10), row('Refunded', rupees(order.refundedPaise), color: c.textMuted)],
                const SizedBox(height: 10),
                row('Due', rupees(order.amountDuePaise)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
