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
import '../../design/widgets/choice_card.dart';
import '../../design/widgets/id_button.dart';
import 'order_repository.dart';
import 'orders_list.dart';

/// "Pay ₹180 for ID001042": what is still owed on an order, paid online now or left for cash at delivery.
Future<void> showPayDueSheet(BuildContext context, OrderDto order) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PayDueSheet(order: order),
    );

class _PayDueSheet extends ConsumerStatefulWidget {
  const _PayDueSheet({required this.order});
  final OrderDto order;

  @override
  ConsumerState<_PayDueSheet> createState() => _PayDueSheetState();
}

class _PayDueSheetState extends ConsumerState<_PayDueSheet> {
  bool _online = true;
  bool _working = false;
  String? _error;

  Future<void> _go() async {
    final order = widget.order;
    if (_online) {
      final router = GoRouter.of(context);
      Navigator.pop(context);
      await router.push(Routes.pay(order.id, due: true), extra: order);
      return;
    }
    // Cash: an online order that was never paid has to become a cash one so the partner collects it.
    if (order.paymentMethod == PaymentMethod.cod) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await ref.read(orderRepositoryProvider).payOnDelivery(order.id);
      ref.invalidate(orderProvider(order.id));
      refreshOrders(ref);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('OK. Pay ${rupees(order.amountDuePaise)} in cash when your clothes are delivered.')));
    } on ApiFailure catch (e) {
      if (mounted) {
        setState(() {
          _working = false;
          _error = e.isConnectivity ? "You're offline. Please try again." : "Couldn't switch to cash on delivery. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final o = widget.order;
    final due = rupees(o.amountDuePaise);
    final delivery = '${dayLong(o.deliveryDate, today: istToday())}, ${windowFromLabel(o.deliverySlotLabel)}';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(IdSpace.s4, 0, IdSpace.s4, IdSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text.rich(TextSpan(text: 'Pay $due for ', children: [TextSpan(text: o.orderNumber, style: t.orderId.copyWith(fontSize: 18))]), style: t.titleLg),
            ),
            const SizedBox(height: IdSpace.s1),
            Text(
              '${piecesLabel(o)}${o.pickedUpAt != null ? ', ironed' : ''}. Delivery $delivery.',
              style: t.bodyLg.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: IdSpace.s4),
            ChoiceCard(icon: LucideIcons.smartphone, title: 'Pay online now', description: 'UPI, cards and netbanking', selected: _online, onTap: _working ? () {} : () => setState(() => _online = true)),
            const SizedBox(height: IdSpace.s2),
            ChoiceCard(
              icon: LucideIcons.banknote,
              title: 'Cash at delivery',
              description: 'Pay your partner when the clothes come back',
              selected: !_online,
              onTap: _working ? () {} : () => setState(() => _online = false),
            ),
            if (_error != null) ...[
              const SizedBox(height: IdSpace.s3),
              Semantics(liveRegion: true, child: Text(_error!, style: t.body.copyWith(color: c.danger))),
            ],
            const SizedBox(height: IdSpace.s4),
            IdButton(label: _online ? 'Pay $due' : 'Pay $due in cash at delivery', expand: true, loading: _working, onPressed: _go),
            const SizedBox(height: IdSpace.s2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_online ? LucideIcons.shieldCheck : LucideIcons.banknote, size: IdSize.iconSm, color: c.textMuted),
                const SizedBox(width: 6),
                Flexible(child: Text(_online ? 'Secure payment by Razorpay' : 'You pay in cash when your clothes are delivered', style: t.caption.copyWith(color: c.textMuted), textAlign: TextAlign.center)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
