import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/money.dart';
import '../../core/order_status.dart';
import '../../core/order_text.dart';
import '../../core/order_timeline.dart';
import '../../core/phone.dart';
import '../../core/slots.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/alert_sheet.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_sheet.dart';
import '../../design/widgets/order_timeline.dart';
import '../../design/widgets/state_view.dart';
import '../../design/widgets/surfaces.dart';
import '../basket/basket.dart';
import '../support/support.dart';
import 'cancel_order.dart';
import 'order_repository.dart';
import 'pay_due.dart';

/// One order: where it is, who has it, what is owed, and what to do next. Shows [initial] (from the
/// list) at once, then the order as the API has it now.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId, this.initial});

  final String orderId;
  final OrderDto? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderProvider(orderId));
    final order = async.value ?? initial;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(
          leading: _back(context),
          title: Text('Order', style: context.text.titleLg),
        ),
        body: async.hasError
            ? _LoadFailure(
                offline: ApiFailure.from(async.error!).isConnectivity,
                onRetry: () => ref.invalidate(orderProvider(orderId)),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    final finished =
        order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled;
    final delayed =
        order.status == OrderStatus.pending && order.dispatchFailedAt != null;

    return Scaffold(
      appBar: AppBar(
        leading: _back(context),
        title: Text.rich(
          TextSpan(
            text: 'Order ',
            children: [
              TextSpan(
                text: order.orderNumber,
                style: context.text.orderId.copyWith(fontSize: 18),
              ),
            ],
          ),
          style: context.text.titleLg,
        ),
        actions: [
          if (order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled)
            IconButton(
              icon: const Icon(LucideIcons.circleQuestionMark),
              tooltip: 'Get help with this order',
              onPressed: () => showOrderHelp(context, ref, order),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(orderProvider(orderId));
          await ref
              .read(orderProvider(orderId).future)
              .then((_) {}, onError: (_) {});
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            IdSpace.s5,
            IdSpace.s5,
            IdSpace.s5,
            IdSpace.s6,
          ),
          children: [
            _Hero(order: order, delayed: delayed),
            const SizedBox(height: IdSpace.s4),
            if (order.status == OrderStatus.cancelled)
              ..._cancelledBody(context, order)
            else if (order.status == OrderStatus.delivered)
              ..._deliveredBody(context, ref, order)
            else
              ..._activeBody(context, ref, order, delayed: delayed),
          ],
        ),
      ),
      bottomNavigationBar: _footer(
        context,
        ref,
        order,
        finished: finished,
        delayed: delayed,
      ),
    );
  }

  Widget? _footer(
    BuildContext context,
    WidgetRef ref,
    OrderDto order, {
    required bool finished,
    required bool delayed,
  }) {
    if (finished) {
      return _Footer(
        actions: [
          IdButton(
            label: order.status == OrderStatus.cancelled
                ? 'Book again'
                : 'Book the same again',
            expand: true,
            onPressed: () => bookAgain(context, ref, order),
          ),
        ],
      );
    }
    final pay = canPayNow(order);
    final cancel = canCancel(order);
    if (pay) {
      final amount = rupees(order.amountDuePaise);
      return _Footer(
        actions: [
          IdButton(
            label: order.paymentMethod == PaymentMethod.online
                ? 'Pay $amount'
                : 'Pay $amount online',
            expand: true,
            onPressed: () => showPayDueSheet(context, order),
          ),
          if (cancel)
            IdButton.outline(
              label: 'Cancel order',
              expand: true,
              onPressed: () => cancelOrder(context, order),
            ),
        ],
      );
    }
    // A late pickup keeps its cancel button in the notice, up top.
    if (cancel && !delayed) {
      return _Footer(
        actions: [
          IdButton.outline(
            label: 'Cancel order',
            expand: true,
            onPressed: () => cancelOrder(context, order),
          ),
        ],
        caption: 'Free to cancel until your clothes are picked up.',
      );
    }
    return null;
  }

  Widget _back(BuildContext context) => BackButton(
    onPressed: () =>
        context.canPop() ? context.pop() : context.go(Routes.orders),
  );

  List<Widget> _activeBody(
    BuildContext context,
    WidgetRef ref,
    OrderDto order, {
    required bool delayed,
  }) {
    final partner = partnerFor(order);
    final due = canPayNow(order);
    return [
      if (delayed) ...[
        _DelayedNotice(order: order),
        const SizedBox(height: IdSpace.s4),
      ],
      IdCard(child: OrderTimeline(steps: buildTimeline(order))),
      if (partner != null) ...[
        const SizedBox(height: IdSpace.s4),
        _PartnerRow(person: partner, caption: partnerCaption(order)),
      ] else if (!delayed) ...[
        const SizedBox(height: IdSpace.s4),
        const _Notice(
          icon: LucideIcons.user,
          tone: _NoticeTone.info,
          text: "You'll see your partner's name and number here once they accept.",
        ),
      ],
      if (due) ...[
        const SizedBox(height: IdSpace.s4),
        _Notice(
          icon: order.paymentMethod == PaymentMethod.online
              ? LucideIcons.circleAlert
              : LucideIcons.banknote,
          tone: _NoticeTone.warning,
          text: dueText(order),
        ),
      ],
      const SizedBox(height: IdSpace.s4),
      _BillRow(order: order),
    ];
  }

  List<Widget> _deliveredBody(
    BuildContext context,
    WidgetRef ref,
    OrderDto order,
  ) {
    final c = context.colors;
    final t = context.text;
    final paid = order.paymentStatus == PaymentStatus.paid;
    final paymentColor = paid ? c.success : c.warning;
    return [
      IdCard(
        child: Column(
          children: [
            _Line(
              'Picked up',
              order.pickedUpAt == null
                  ? '—'
                  : istDateTimeLabel(order.pickedUpAt!),
            ),
            const SizedBox(height: 10),
            _Line('Items', '${pieceCount(order)}, ironed'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    paid ? 'Paid' : 'Payment due',
                    style: t.bodyLg.copyWith(color: c.textMuted),
                  ),
                ),
                const SizedBox(width: IdSpace.s2),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: paid ? c.successSoft : c.warningSoft,
                      borderRadius: BorderRadius.circular(IdRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          paid ? LucideIcons.check : LucideIcons.circleAlert,
                          size: IdSize.iconSm,
                          color: paymentColor,
                        ),
                        const SizedBox(width: IdSpace.s1),
                        Flexible(
                          child: Text(
                            paid
                                ? '${rupees(order.paidPaise)} ${paidHow(order) == 'Paid in cash' ? 'in cash' : 'online'}'
                                : '${rupees(order.amountDuePaise)} due',
                            style: t.labelSm.copyWith(color: paymentColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: IdSpace.s4),
      IdListGroup(
        children: [
          IdListRow(
            icon: LucideIcons.fileText,
            label: 'Items and bill',
            onTap: () => context.push(Routes.bill(order.id), extra: order),
          ),
          IdListRow(
            icon: LucideIcons.circleQuestionMark,
            label: 'Something wrong with an item?',
            onTap: () => showOrderHelp(context, ref, order),
          ),
        ],
      ),
    ];
  }

  List<Widget> _cancelledBody(BuildContext context, OrderDto order) {
    final paid = order.paidPaise > 0;
    final refunded = order.refundedPaise >= order.paidPaise;
    return [
      if (paid)
        _Notice(
          icon: LucideIcons.refreshCw,
          tone: _NoticeTone.info,
          text: refunded
              ? 'Your ${rupees(order.refundedPaise)} refund has been sent to the account you paid from.'
              : '${rupees(order.paidPaise)} is awaiting refund confirmation. Contact support for the current status.',
        ),
      if (paid) const SizedBox(height: IdSpace.s4),
      IdCard(
        child: Column(
          children: [
            _Line(
              'Was booked for',
              '${dayLong(order.pickupDate)}, ${windowFromLabel(order.pickupSlotLabel)}',
            ),
            const SizedBox(height: 10),
            _Line('Items', '${pieceCount(order)}'),
            const SizedBox(height: 10),
            _Line(
              'Amount',
              paid
                  ? '${rupees(order.totalPaise)} · ${refunded ? 'refunded' : 'refund pending'}'
                  : '${rupees(order.totalPaise)} · nothing charged',
            ),
          ],
        ),
      ),
    ];
  }
}

/// Who has the clothes right now: the delivery partner once one is assigned, else the pickup partner.
PersonRefDto? partnerFor(OrderDto o) => switch (o.status) {
  OrderStatus.deliveryAssigned ||
  OrderStatus.outForDelivery => o.deliveryDriver ?? o.pickupDriver,
  OrderStatus.pickupAssigned ||
  OrderStatus.pickedUp ||
  OrderStatus.processing ||
  OrderStatus.readyForDelivery => o.pickupDriver,
  _ => null,
};

String partnerCaption(OrderDto o) => switch (o.status) {
  OrderStatus.pickupAssigned => 'Coming to pick up your clothes',
  OrderStatus.deliveryAssigned => 'Will bring your clothes back',
  OrderStatus.outForDelivery => 'Bringing your clothes back',
  _ => 'Picked up your clothes',
};

/// The warning under the timeline: how much is owed and the ways to pay it.
String dueText(OrderDto o) {
  final amount = rupees(o.amountDuePaise);
  if (o.paymentMethod == PaymentMethod.online) {
    return "$amount isn't paid yet. Pay online now, or switch to cash on delivery.";
  }
  final delivering =
      o.status == OrderStatus.deliveryAssigned ||
      o.status == OrderStatus.outForDelivery;
  final first = o.deliveryDriver?.name?.split(' ').first;
  return delivering && first != null
      ? '$amount is due. Pay $first in cash at the door, or pay online now.'
      : '$amount is due. Pay the partner in cash or pay online now.';
}

/// Opens the cancel sheet, and says so when the order was cancelled.
Future<void> cancelOrder(BuildContext context, OrderDto order) async {
  final messenger = ScaffoldMessenger.of(context);
  final done = await showCancelSheet(context, order);
  if (done) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Order ${order.orderNumber} cancelled')),
      );
  }
}

/// Puts the order's items in the basket and opens it. Asks first if the basket already holds something.
Future<void> bookAgain(
  BuildContext context,
  WidgetRef ref,
  OrderDto order,
) async {
  final lines = <String, int>{
    for (final i in order.items)
      if (i.catalogItemId != null) i.catalogItemId!: i.quantity.toInt(),
  };
  if (lines.isEmpty) {
    context.go(Routes.book);
    return;
  }
  if (!ref.read(basketProvider).isEmpty) {
    final replace = await showIdAlert(
      context,
      icon: LucideIcons.shoppingBag,
      title: 'Replace your basket?',
      body: 'Your basket already has items. This order\'s items will take their place.',
      primaryLabel: 'Replace',
      secondaryLabel: 'Cancel',
      tone: StateTone.primary,
      barrierDismissible: true,
    );
    if (replace != true || !context.mounted) return;
  }
  ref.read(basketProvider.notifier).replaceWith(lines);
  if (context.mounted) await context.push(Routes.basket);
}

/// "Need help with this order?": call or email support, with the order number to quote.
Future<void> showOrderHelp(
  BuildContext context,
  WidgetRef ref,
  OrderDto order,
) {
  final support = Support.of(ref);
  return showIdSheet<void>(
    context,
    builder: (context) {
      final t = context.text;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Need help with this order?', style: t.titleLg),
          ),
          const SizedBox(height: IdSpace.s1),
          Text(
            'Mention ${order.orderNumber} and we\'ll find it straight away.',
            style: t.body.copyWith(color: context.colors.textMuted),
          ),
          const SizedBox(height: IdSpace.s4),
          IdButton(
            label: 'Call ${IndianPhone.display(support.phone)}',
            icon: LucideIcons.phone,
            expand: true,
            onPressed: () => Support.dial(support.phone),
          ),
          if (support.email != null) ...[
            const SizedBox(height: IdSpace.s2),
            IdButton.outline(
              label: 'Email ${support.email}',
              icon: LucideIcons.mail,
              expand: true,
              onPressed: () => Support.mail(support.email!),
            ),
          ],
        ],
      );
    },
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.order, required this.delayed});
  final OrderDto order;
  final bool delayed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final today = istToday();

    if (order.status == OrderStatus.delivered) {
      final by = order.deliveryDriver?.name;
      final when = order.deliveredAt == null
          ? null
          : istDateTimeLabel(order.deliveredAt!);
      return Semantics(
        container: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(IdRadius.xl),
          child: Container(
            color: c.successSoft,
            padding: const EdgeInsets.all(IdSpace.s5),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: c.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.check,
                    size: IdSize.iconLg,
                    color: c.success,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text('Delivered', style: t.headline),
                      ),
                      if (when != null)
                        Text(
                          [when, if (by != null) 'by $by'].join(' · '),
                          style: t.body,
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

    if (order.status == OrderStatus.cancelled) {
      final reason = order.cancelReason;
      final byStaff =
          order.events
              ?.where((e) => e.toStatus == OrderStatus.cancelled)
              .any(
                (e) => e.actorRole != null && e.actorRole != Role.customer,
              ) ??
          false;
      return Container(
        padding: const EdgeInsets.all(IdSpace.s5),
        decoration: BoxDecoration(
          color: c.surfaceSoft,
          borderRadius: BorderRadius.circular(IdRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 28),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(IdRadius.full),
              ),
              alignment: Alignment.center,
              child: Text(
                'Cancelled',
                style: t.labelSm.copyWith(color: c.textMuted),
              ),
            ),
            const SizedBox(height: 6),
            Semantics(
              header: true,
              child: Text(
                byStaff
                    ? 'This order was cancelled'
                    : 'You cancelled this order',
                style: t.headline,
              ),
            ),
            Text(
              [
                if (order.cancelledAt != null)
                  istDateTimeLabel(order.cancelledAt!),
                if (reason != null && reason.isNotEmpty) '"$reason"',
              ].join(' · '),
              style: t.body.copyWith(color: c.textMuted),
            ),
          ],
        ),
      );
    }

    final step = order.status.timelineStep;
    final missed = deliveryEstimateMissed(order);
    final title = delayed ? 'Pickup running late' : order.status.customerLabel;
    final body = missed
        ? 'Delivery estimate missed: ${dayLong(order.deliveryDate)}, ${windowFromLabel(order.deliverySlotLabel)}. Contact support for an update.'
        : switch (order.status) {
            OrderStatus.pending || OrderStatus.pickupAssigned =>
              delayed
                  ? 'Window ${dayPhrase(order.pickupDate, today: today)}, ${windowFromLabel(order.pickupSlotLabel)}'
                  : 'Pickup ${dayPhrase(order.pickupDate, today: today)}, ${windowFromLabel(order.pickupSlotLabel)}',
            OrderStatus.deliveryAssigned || OrderStatus.outForDelivery =>
              'Arriving ${dayPhrase(order.deliveryDate, today: today)}, ${windowFromLabel(order.deliverySlotLabel)}',
            _ =>
              'Back by ${dayLong(order.deliveryDate, today: today)}, ${windowFromLabel(order.deliverySlotLabel)}',
          };
    return Semantics(
      container: true,
      liveRegion: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(IdRadius.xl),
        child: Container(
          width: double.infinity,
          color: c.surface,
          padding: const EdgeInsets.all(IdSpace.s5),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step $step of 5',
                    style: t.labelSm.copyWith(color: c.textMuted),
                  ),
                  Text(title, style: t.headline.copyWith(color: c.text)),
                  Text(body, style: t.body.copyWith(color: c.text)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _NoticeTone { info, warning }

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.tone,
    required this.text,
    this.actions = const [],
  });

  final IconData icon;
  final _NoticeTone tone;
  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final warning = tone == _NoticeTone.warning;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: warning ? c.warningSoft : c.primarySoft,
          borderRadius: BorderRadius.circular(IdRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: IdSize.iconMd,
                  color: warning ? c.warning : c.onPrimarySoft,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: context.text.body)),
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: IdSpace.s3),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Wrap(
                  spacing: IdSpace.s2,
                  runSpacing: IdSpace.s1,
                  children: actions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "All our partners nearby are busy…" with a way to call or cancel.
class _DelayedNotice extends ConsumerWidget {
  const _DelayedNotice({required this.order});
  final OrderDto order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final support = Support.of(ref);
    final window = windowFromLabel(order.pickupSlotLabel);
    final end = window.split(' – ').last;
    return _Notice(
      icon: LucideIcons.clock,
      tone: _NoticeTone.warning,
      text:
          "All our partners nearby are busy. We're still trying and will call you if we can't make it by $end.",
      actions: [
        IdButton.outline(
          label: 'Call us',
          onPressed: () => Support.dial(support.phone),
        ),
        IdButton.text(
          label: 'Cancel order',
          onPressed: () => cancelOrder(context, order),
        ),
      ],
    );
  }
}

class _PartnerRow extends StatelessWidget {
  const _PartnerRow({required this.person, required this.caption});
  final PersonRefDto person;
  final String caption;

  static String _initials(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '•';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final name = person.name ?? 'Your partner';
    final first = name.split(' ').first;
    return IdCard(
      padding: const EdgeInsets.symmetric(horizontal: IdSpace.s5, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.primarySoft,
              shape: BoxShape.circle,
            ),
            child: ExcludeSemantics(
              child: Text(
                _initials(person.name),
                style: t.title.copyWith(color: c.onPrimarySoft),
              ),
            ),
          ),
          const SizedBox(width: IdSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: t.title),
                Text(caption, style: t.caption.copyWith(color: c.textMuted)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Call $first',
            style: IconButton.styleFrom(
              side: BorderSide(color: c.borderStrong),
              foregroundColor: c.primary,
              fixedSize: const Size(48, 48),
            ),
            icon: const Icon(LucideIcons.phone),
            onPressed: () => Support.dial(person.phone),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.order});
  final OrderDto order;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final paid = order.paymentStatus == PaymentStatus.paid;
    return IdCard(
      onTap: () => context.push(Routes.bill(order.id), extra: order),
      child: Semantics(
        button: true,
        label: 'View bill. ${piecesLabel(order)}, ${rupees(order.totalPaise)}',
        excludeSemantics: true,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${piecesLabel(order)} · ${rupees(order.totalPaise)}',
                    style: t.title,
                  ),
                  Text(
                    paid ? paidHow(order) : itemsSummary(order),
                    style: t.caption.copyWith(color: c.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text('View bill', style: t.label.copyWith(color: c.primary)),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.k, this.v);
  final String k;
  final String v;

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
        child: Text(v, style: context.text.bodyLg, textAlign: TextAlign.end),
      ),
    ],
  );
}

class _Footer extends StatelessWidget {
  const _Footer({required this.actions, this.caption});

  final List<Widget> actions;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            IdSpace.s5,
            IdSpace.s3,
            IdSpace.s5,
            IdSpace.s3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, a) in actions.indexed) ...[
                if (i > 0) const SizedBox(height: IdSpace.s2),
                a,
              ],
              if (caption != null) ...[
                const SizedBox(height: IdSpace.s2),
                Text(
                  caption!,
                  style: context.text.caption.copyWith(color: c.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.offline, required this.onRetry});
  final bool offline;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(IdSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              offline ? LucideIcons.wifiOff : LucideIcons.circleAlert,
              size: 32,
              color: c.danger,
            ),
            const SizedBox(height: IdSpace.s4),
            Text("Couldn't load this order", style: t.titleLg),
            const SizedBox(height: IdSpace.s2),
            Text(
              offline
                  ? "You're offline. Check your connection and try again."
                  : 'Please try again in a moment.',
              style: t.body.copyWith(color: c.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: IdSpace.s4),
            IdButton.tonal(
              label: 'Try again',
              icon: LucideIcons.refreshCw,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
