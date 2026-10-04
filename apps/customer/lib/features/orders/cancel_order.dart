import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/money.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/slot_picker.dart';
import 'order_repository.dart';
import 'orders_list.dart';

/// Why customers cancel, as the design lists them. Optional: the order can be cancelled without one.
const cancelReasons = [
  "I won't be at home",
  'I booked by mistake',
  "The time doesn't suit me",
  'Something else',
];

/// Whether an order can still be cancelled by the customer: until the clothes are picked up.
bool canCancel(OrderDto o) =>
    o.status == OrderStatus.pending || o.status == OrderStatus.pickupAssigned;

/// Why a cancel did not go through, in words for the customer.
String cancelFailureText(ApiFailure e) {
  if (e.isConnectivity) {
    return "You're offline. Nothing was cancelled. Check your connection and try again.";
  }
  if (e.code == 'INVALID_TRANSITION') {
    return 'Your clothes have already been picked up, so this order can no longer be cancelled. Call us if you need help.';
  }
  return "Couldn't cancel the order. Please try again.";
}

/// "Cancel this order?" Resolves true once the order is cancelled.
Future<bool> showCancelSheet(BuildContext context, OrderDto order) async {
  final cancelled = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CancelSheet(order: order),
  );
  return cancelled ?? false;
}

class _CancelSheet extends ConsumerStatefulWidget {
  const _CancelSheet({required this.order});
  final OrderDto order;

  @override
  ConsumerState<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends ConsumerState<_CancelSheet> {
  String? _reason;
  bool _cancelling = false;
  String? _error;

  Future<void> _cancel() async {
    setState(() {
      _cancelling = true;
      _error = null;
    });
    final id = widget.order.id;
    try {
      await ref.read(orderRepositoryProvider).cancel(id, reason: _reason);
      ref.invalidate(orderProvider(id));
      refreshOrders(ref);
      if (mounted) Navigator.pop(context, true);
    } on ApiFailure catch (e) {
      // A refusal means the order moved on: show it as it is now.
      if (e.code == 'INVALID_TRANSITION') ref.invalidate(orderProvider(id));
      if (mounted) {
        setState(() {
          _cancelling = false;
          _error = cancelFailureText(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final o = widget.order;
    final paid = o.paidPaise > 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          IdSpace.s4,
          0,
          IdSpace.s4,
          IdSpace.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Cancel this order?', style: t.titleLg),
            ),
            const SizedBox(height: IdSpace.s1),
            Text(
              'Tell us why (optional). It helps us improve.',
              style: t.bodyLg.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: IdSpace.s4),
            for (final reason in cancelReasons) ...[
              ReasonTile(
                label: reason,
                selected: _reason == reason,
                onTap: _cancelling
                    ? null
                    : () => setState(
                        () => _reason = _reason == reason ? null : reason,
                      ),
              ),
              const SizedBox(height: IdSpace.s2),
            ],
            const SizedBox(height: IdSpace.s1),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(IdRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    paid ? LucideIcons.refreshCw : LucideIcons.circleCheck,
                    size: IdSize.iconMd,
                    color: c.onPrimarySoft,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      paid
                          ? 'You paid ${rupees(o.paidPaise)} online. After cancellation, contact support to confirm the refund status.'
                          : "Nothing has been charged, so there's nothing to refund.",
                      style: t.body,
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: IdSpace.s3),
              Semantics(
                liveRegion: true,
                child: Text(_error!, style: t.body.copyWith(color: c.danger)),
              ),
            ],
            const SizedBox(height: IdSpace.s4),
            IdButton.danger(
              label: 'Cancel order',
              expand: true,
              loading: _cancelling,
              onPressed: _cancel,
            ),
            const SizedBox(height: IdSpace.s2),
            IdButton.outline(
              label: 'Keep order',
              expand: true,
              onPressed: _cancelling
                  ? null
                  : () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }
}
