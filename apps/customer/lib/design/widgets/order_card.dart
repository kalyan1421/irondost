import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/money.dart';
import '../../core/order_status.dart';
import '../../core/order_text.dart';
import '../../core/slots.dart';
import '../../data/api/export.dart';
import '../theme.dart';
import 'surfaces.dart';

/// An order in the list. Active orders show pickup and delivery windows and a Track (or Pay now)
/// action; finished ones show what happened to the money and a Details action.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onOpen,
    this.onPay,
    this.onRepeat,
  });

  final OrderDto order;

  /// Opens the order (Track / Details).
  final VoidCallback onOpen;

  /// "Pay now", shown when something is due.
  final VoidCallback? onPay;

  /// "Book again", offered on finished orders: puts the same items in a new basket.
  final VoidCallback? onRepeat;

  bool get _finished =>
      order.status == OrderStatus.delivered ||
      order.status == OrderStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final due = !_finished && canPayNow(order);
    final today = istToday();

    final summary = _finished
        ? '${order.status == OrderStatus.cancelled ? 'Cancelled${order.pickedUpAt == null ? ' before pickup' : ''}' : itemsSummary(order)}'
              ' · ${istDayLabel((order.status == OrderStatus.cancelled ? order.cancelledAt : order.deliveredAt) ?? order.updatedAt)}'
        : itemsSummary(order);

    final amountAndNote = Wrap(
      spacing: IdSpace.s2,
      runSpacing: IdSpace.s1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          rupees(order.totalPaise),
          style: t.titleLg.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            color: order.status == OrderStatus.cancelled ? c.textMuted : null,
            decoration: order.status == OrderStatus.cancelled
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        if (_finished)
          Text(
            settledNote(order),
            style: t.caption.copyWith(color: c.textMuted),
          )
        else
          _PaymentChip(order, due: due),
      ],
    );
    final details = TextButton(
      onPressed: due && onPay != null ? onPay : onOpen,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.only(left: IdSpace.s3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            due && onPay != null
                ? 'Pay now'
                : (_finished ? 'Details' : 'Track'),
          ),
          const SizedBox(width: 2),
          const Icon(LucideIcons.chevronRight, size: IdSize.iconSm),
        ],
      ),
    );

    return Semantics(
      container: true,
      label:
          '${order.orderNumber}, ${order.status.customerLabel}, ${rupees(order.totalPaise)}',
      child: IdCard(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.status.customerLabel, style: t.titleLg),
                ),
                const SizedBox(width: IdSpace.s2),
                Flexible(
                  child: Text(
                    order.orderNumber,
                    style: t.orderId.copyWith(color: c.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: IdSpace.s1),
            Text(summary, style: t.body.copyWith(color: c.textMuted)),
            if (!_finished) ...[
              const SizedBox(height: IdSpace.s3),
              Container(
                padding: const EdgeInsets.symmetric(vertical: IdSpace.s3),
                child: Builder(
                  builder: (context) {
                    final pickup = order.pickedUpAt != null
                        ? _Kv('Picked up', istDayLabel(order.pickedUpAt!))
                        : _Kv(
                            'Pickup',
                            '${dayLong(order.pickupDate, today: today)}, ${windowFromLabel(order.pickupSlotLabel)}',
                          );
                    final delivery = _Kv(
                      deliveryEstimateMissed(order)
                          ? 'Delivery estimate missed'
                          : 'Delivery',
                      '${dayLong(order.deliveryDate, today: today)}, ${windowFromLabel(order.deliverySlotLabel)}',
                    );
                    // Side by side until large text leaves each half too narrow to read, then one above the other.
                    return MediaQuery.textScalerOf(context).scale(1) > 1.3
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              pickup,
                              const SizedBox(height: IdSpace.s2),
                              delivery,
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: pickup),
                              const SizedBox(width: IdSpace.s3),
                              Expanded(child: delivery),
                            ],
                          );
                  },
                ),
              ),
            ],
            const SizedBox(height: IdSpace.s3),
            if (_finished && onRepeat != null) ...[
              amountAndNote,
              // Two short actions in a Wrap, so large text puts one under the other instead of
              // overflowing a Row.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: onRepeat,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(right: IdSpace.s3),
                    ),
                    icon: const Icon(LucideIcons.repeat, size: IdSize.iconSm),
                    label: const Text('Book again'),
                  ),
                  details,
                ],
              ),
            ] else
              Row(
                children: [
                  Expanded(child: amountAndNote),
                  details,
                ],
              ),
          ],
        ),
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
      Text(
        k,
        style: context.text.caption.copyWith(color: context.colors.textMuted),
      ),
      Text(v, style: context.text.label.copyWith(fontWeight: FontWeight.w600)),
    ],
  );
}

/// "Paid", "₹180 due" or "Pay at delivery".
class _PaymentChip extends StatelessWidget {
  const _PaymentChip(this.order, {required this.due});
  final OrderDto order;
  final bool due;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final paid = order.paymentStatus == PaymentStatus.paid;
    final (bg, fg, icon, text) = paid
        ? (c.successSoft, c.success, LucideIcons.check, 'Paid')
        : due
        ? (
            c.warningSoft,
            c.warning,
            null,
            '${rupees(order.amountDuePaise)} due',
          )
        : (c.surfaceSoft, c.textMuted, null, 'Pay at delivery');
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

/// The design's two-way switch under a screen title: "Active (2)" / "Past".
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  /// Read out by screen readers.
  final String label;
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      container: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: c.surface),
        child: Row(
          children: [
            for (final (i, option) in options.indexed)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == selected,
                  label: option,
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(IdRadius.sm),
                    onTap: () => onSelect(i),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: IdSize.touchTarget,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: i == selected ? c.primary : c.border,
                            width: i == selected ? 2 : 1,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(IdRadius.sm),
                      ),
                      child: Text(
                        option,
                        style: t.label.copyWith(
                          color: i == selected ? c.primary : c.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
