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
import 'payment.dart';

/// Pays an order online: opens Razorpay, then waits for the server to confirm. It stays on screen
/// through the whole thing (preparing, the Razorpay window, confirming) and ends at the confirmation
/// when paid, or here with a way forward when not.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.orderId, this.initial, this.due = false});

  final String orderId;

  /// Paying what is still owed on an existing order, not a booking that was just made: ends at the
  /// receipt, and backing out returns to the order instead of Home.
  final bool due;

  /// The order as just placed or listed, shown at once; fetched again if missing.
  final OrderDto? initial;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    // After the first frame: a provider must not change while the tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(paymentProvider(widget.orderId).notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.orderId;
    ref.listen(paymentProvider(id), (prev, next) {
      if ((next.phase == PaymentPhase.paid || next.phase == PaymentPhase.cash) && prev?.phase != next.phase) {
        if (!widget.due) {
          context.go(Routes.confirmed(id), extra: next.order);
        } else if (next.phase == PaymentPhase.paid) {
          context.pushReplacement(Routes.paid(id), extra: next.order);
        } else {
          final messenger = ScaffoldMessenger.of(context);
          context.pop();
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text("OK. You'll pay in cash when your clothes are delivered.")));
        }
      }
    });
    final payment = ref.watch(paymentProvider(id));
    final order = ref.watch(orderProvider(id)).value ?? widget.initial;
    final controller = ref.read(paymentProvider(id).notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // Never walk away from a payment in progress; once it has ended, back means home.
        if (didPop || payment.busy) return;
        if (widget.due) {
          context.pop();
        } else {
          context.go(Routes.home);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: switch (payment.phase) {
            PaymentPhase.failed => _Failed(
                failure: payment.failure ?? PaymentFailure.other,
                order: order,
                due: widget.due,
                onRetry: controller.start,
                onCash: () => _cash(controller),
              ),
            PaymentPhase.unconfirmed => _Unconfirmed(order: order, onCheck: controller.checkAgain),
            _ => _Working(phase: payment.phase, order: order),
          },
        ),
      ),
    );
  }

  Future<void> _cash(PaymentController controller) async {
    final ok = await controller.payCash();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text("Couldn't switch to cash on delivery. Please try again.")));
    }
  }
}

/// A centred message with an icon, and up to two buttons pinned to the bottom (the design's payment screens).
class _Layout extends StatelessWidget {
  const _Layout({required this.icon, required this.tone, required this.title, required this.body, this.details, this.notice, this.actions = const [], this.caption});

  final Widget icon;
  final Color tone;
  final String title;
  final String body;
  final Widget? details;
  final Widget? notice;
  final List<Widget> actions;
  final Widget? caption;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
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
                      child: Container(width: 120, height: 120, decoration: BoxDecoration(color: tone, shape: BoxShape.circle), alignment: Alignment.center, child: icon),
                    ),
                    const SizedBox(height: IdSpace.s6),
                    Semantics(header: true, liveRegion: true, child: Text(title, style: t.headline, textAlign: TextAlign.center)),
                    const SizedBox(height: IdSpace.s3),
                    Text(body, style: t.bodyLg.copyWith(color: c.textMuted), textAlign: TextAlign.center),
                    if (notice != null) ...[const SizedBox(height: IdSpace.s4), notice!],
                    if (details != null) ...[const SizedBox(height: IdSpace.s4), details!],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s3, IdSpace.s4, IdSpace.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final (i, a) in actions.indexed) ...[if (i > 0) const SizedBox(height: IdSpace.s2), a]],
            ),
          ),
        if (caption != null) Padding(padding: const EdgeInsets.only(bottom: IdSpace.s4), child: caption),
        if (caption == null) const SizedBox(height: IdSpace.s2),
      ],
    );
  }
}

class _RazorpayCaption extends StatelessWidget {
  const _RazorpayCaption();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.shieldCheck, size: IdSize.iconSm, color: c.textMuted),
        const SizedBox(width: 6),
        Text('Secure payment by Razorpay', style: context.text.caption.copyWith(color: c.textMuted)),
      ],
    );
  }
}

/// Order and amount, as a small card.
class _OrderCard extends StatelessWidget {
  const _OrderCard(this.order);
  final OrderDto? order;

  @override
  Widget build(BuildContext context) {
    final o = order;
    if (o == null) return const SizedBox.shrink();
    final c = context.colors;
    final t = context.text;
    Widget row(String k, Widget v) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(k, style: t.bodyLg.copyWith(color: c.textMuted)), v],
        );
    return IdCard(
      child: Column(
        children: [
          row('Order', Text(o.orderNumber, style: t.orderId)),
          const SizedBox(height: IdSpace.s2),
          row('Amount', Text(rupees(o.amountDuePaise > 0 ? o.amountDuePaise : o.totalPaise), style: t.label.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _Working extends StatelessWidget {
  const _Working({required this.phase, required this.order});

  final PaymentPhase phase;
  final OrderDto? order;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (title, body) = switch (phase) {
      PaymentPhase.preparing => ('Getting your payment ready', 'One moment. Please keep the app open.'),
      PaymentPhase.inCheckout => ('Complete your payment', 'Finish in the payment window. Please keep the app open.'),
      _ => ('Confirming your payment', 'This takes a few seconds. Please keep the app open.'),
    };
    return Semantics(
      container: true,
      child: _Layout(
        icon: SizedBox.square(dimension: 52, child: CircularProgressIndicator(strokeWidth: 4, color: c.primary)),
        tone: c.primarySoft,
        title: title,
        body: body,
        details: _OrderCard(order),
        caption: const _RazorpayCaption(),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.failure, required this.order, required this.due, required this.onRetry, required this.onCash});

  final PaymentFailure failure;
  final OrderDto? order;
  final bool due;
  final VoidCallback onRetry;
  final VoidCallback onCash;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (title, body) = switch (failure) {
      PaymentFailure.declined => ("Payment didn't go through", 'Your bank or Razorpay declined it. If any money left your account, your bank returns it automatically.'),
      PaymentFailure.cancelled => ('Payment cancelled', 'You closed the payment window. Nothing was charged.'),
      PaymentFailure.offline => ('No connection', "We couldn't reach IronDost. Nothing was charged. Check your connection and try again."),
      PaymentFailure.unavailable => ("Online payment isn't available", 'You can pay cash at delivery instead, or try again a little later.'),
      PaymentFailure.orderCancelled => ('This order was cancelled', "There's nothing to pay."),
      PaymentFailure.other => ("We couldn't confirm the payment", 'If any money left your account, your bank returns it automatically. You can try again or pay cash at delivery.'),
    };
    final o = order;
    final amount = o == null ? '' : ' · ${rupees(o.amountDuePaise > 0 ? o.amountDuePaise : o.totalPaise)}';
    final cancelled = failure == PaymentFailure.orderCancelled;

    return _Layout(
      icon: Icon(failure == PaymentFailure.offline ? LucideIcons.wifiOff : LucideIcons.circleX, size: 52, color: c.danger),
      tone: c.dangerSoft,
      title: title,
      body: body,
      notice: o == null || cancelled || due ? null : _StillBooked(o),
      actions: cancelled
          ? [IdButton(label: due ? 'Back to order' : 'Back to home', onPressed: () => due ? context.pop() : context.go(Routes.home))]
          : [
              if (failure != PaymentFailure.unavailable) IdButton(label: 'Try again$amount', onPressed: onRetry),
              IdButton.outline(label: 'Pay cash at delivery instead', onPressed: onCash),
              IdButton.text(label: due ? 'Back to order' : 'Back to home', onPressed: () => due ? context.pop() : context.go(Routes.home)),
            ],
    );
  }
}

/// "Your pickup is still booked for today, 4 – 8 PM. Order ID001046."
class _StillBooked extends StatelessWidget {
  const _StillBooked(this.order);
  final OrderDto order;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final day = order.pickupDate == istToday() ? 'today' : dayLong(order.pickupDate);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.successSoft, borderRadius: BorderRadius.circular(IdRadius.md)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.circleCheck, size: IdSize.iconMd, color: c.success),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Your pickup is still booked for $day, ${windowFromLabel(order.pickupSlotLabel)}. Order '),
                    TextSpan(text: order.orderNumber, style: t.orderId),
                    const TextSpan(text: '.'),
                  ],
                ),
                style: t.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Razorpay reported a payment but the server has not recorded it yet.
class _Unconfirmed extends StatelessWidget {
  const _Unconfirmed({required this.order, required this.onCheck});

  final OrderDto? order;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Layout(
      icon: Icon(LucideIcons.clock, size: 52, color: c.warning),
      tone: c.warningSoft,
      title: "We're still confirming",
      body: "If money was taken, your order will show Paid shortly. You don't need to pay again.",
      details: _OrderCard(order),
      actions: [
        IdButton(label: 'Check again', onPressed: onCheck),
        IdButton.outline(label: 'Go to my orders', onPressed: () => context.go(Routes.orders)),
      ],
      caption: const _RazorpayCaption(),
    );
  }
}
