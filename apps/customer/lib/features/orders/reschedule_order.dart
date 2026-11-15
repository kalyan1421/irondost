import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/slots.dart';
import '../../core/uuid.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_sheet.dart';
import '../../design/widgets/state_view.dart';
import '../schedule/schedule.dart';
import '../schedule/schedule_screen.dart';
import '../support/support.dart';
import 'order_repository.dart';
import 'orders_list.dart';

/// "2 changes left", for the row on the order and the line on the screen.
String changesLeft(num remaining) => remaining.toInt() == 1 ? '1 change left' : '${remaining.toInt()} changes left';

/// Why a time change did not go through, in words for the customer.
String rescheduleFailureText(ApiFailure e) {
  if (e.isConnectivity) return "You're offline. Nothing was changed. Check your connection and try again.";
  switch (e.code) {
    case 'RESCHEDULE_NOT_ALLOWED':
      return "This order can't be changed any more. Your clothes may already be picked up. Call us if you need help.";
    case 'RESCHEDULE_LIMIT':
      return "You've used all the changes for this order. Call us if you need another.";
    case 'RESCHEDULE_UNCHANGED':
      return "That's already the time for this order.";
  }
  return "Couldn't change the time. Please try again.";
}

/// The API refused a time: closed, too far ahead, or too soon after the pickup. The windows on screen are out of date.
bool rescheduleTimeRefused(ApiFailure e) => switch (e.code) {
  'PICKUP_SLOT_CLOSED' || 'PICKUP_TOO_FAR_AHEAD' || 'DELIVERY_TOO_SOON' || 'DELIVERY_TOO_FAR_AHEAD' || 'INVALID_DATE' => true,
  _ => false,
};

/// The pickup window the customer chose filled up while they were deciding: the windows on screen are out of date.
bool rescheduleSlotFull(ApiFailure e) => e.code == 'SLOT_FULL';

/// How a confirmation ended.
enum _Outcome { done, timesRefused, slotFull, failed }

/// "Change pickup time": the booking's own picker, starting on this order's windows. Nothing changes until the
/// customer has reviewed the change and confirmed it. Shows [initial] (from the order screen) at once.
class RescheduleScreen extends ConsumerStatefulWidget {
  const RescheduleScreen({super.key, required this.orderId, this.initial});

  final String orderId;
  final OrderDto? initial;

  @override
  ConsumerState<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends ConsumerState<RescheduleScreen> {
  /// The change the current idempotency key belongs to. Asking again for the same change reuses the key, so a
  /// timeout that hid a successful change can never use up a second one.
  String? _signature;
  String? _key;

  RescheduleStart _startOf(OrderDto o) => (
    orderId: o.id,
    pickup: (date: o.pickupDate, slot: o.pickupSlot),
    delivery: (date: o.deliveryDate, slot: o.deliverySlot),
  );

  Future<void> _review(OrderDto order, RescheduleStart start, Schedule schedule) async {
    final pickup = schedule.pickup!;
    final delivery = schedule.delivery!;
    final signature = '${order.id}|${pickup.date}|${pickup.slot.name}|${delivery.date}|${delivery.slot.name}';
    if (signature != _signature) {
      _signature = signature;
      _key = newUuid();
    }
    final key = _key!;
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await showIdSheet<_Outcome>(
      context,
      builder: (_) => _ConfirmSheet(order: order, start: start, pickup: pickup, delivery: delivery, today: schedule.today, idempotencyKey: key),
    );
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case _Outcome.done:
        _signature = null;
        _key = null;
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(slotKey(pickup) == start.pickup ? 'Delivery time changed' : 'Pickup time changed')));
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.order(order.id));
        }
      case _Outcome.timesRefused:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text("That time isn't available any more. Please pick another.")));
      case _Outcome.slotFull:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('That pickup time just filled up. Please pick another. Your current time is unchanged.')));
      case _Outcome.failed:
        // The key was refused for another change: start a new attempt.
        _signature = null;
        _key = null;
    }
  }

  void _back() => context.canPop() ? context.pop() : context.go(Routes.order(widget.orderId));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderProvider(widget.orderId));
    final order = async.value ?? widget.initial;
    final appBar = AppBar(
      leading: BackButton(onPressed: _back),
      title: Text('Change pickup time', style: context.text.titleLg),
    );

    if (order == null) {
      return Scaffold(
        appBar: appBar,
        body: async.hasError
            ? ScheduleLoadFailure(offline: ApiFailure.from(async.error!).isConnectivity, onRetry: () => ref.invalidate(orderProvider(widget.orderId)))
            : const ScheduleLoading(),
      );
    }
    if (!order.canReschedule) return Scaffold(appBar: appBar, body: _Closed(order: order, onBack: _back));

    final start = _startOf(order);
    final schedule = ref.watch(rescheduleScheduleProvider(start));
    final current = schedule.value;
    final changed = current != null && current.isComplete && (slotKey(current.pickup!) != start.pickup || slotKey(current.delivery!) != start.delivery);

    return Scaffold(
      appBar: appBar,
      body: schedule.when(
        loading: () => const ScheduleLoading(),
        error: (e, _) => ScheduleLoadFailure(offline: ApiFailure.from(e).isConnectivity, onRetry: () => ref.invalidate(pickupSlotsProvider)),
        data: (sch) => sch.isEmpty
            ? const ScheduleNothingOpen()
            : SchedulePicker(
                schedule: sch,
                picks: ref.read(rescheduleChoiceProvider(start).notifier),
                onChangeDelivery: () => showDeliverySheet(
                  context,
                  source: rescheduleScheduleProvider(start),
                  picks: ref.read(rescheduleChoiceProvider(start).notifier),
                ),
                before: [_Current(order: order, today: sch.today)],
                afterDelivery: [if (sch.pickup != null) _DeliveryNote(schedule: sch, start: start)],
              ),
      ),
      bottomNavigationBar: _Footer(enabled: changed, onReview: changed ? () => _review(order, start, current) : null),
    );
  }
}

/// What the order has now, and how many changes are left.
class _Current extends StatelessWidget {
  const _Current({required this.order, required this.today});
  final OrderDto order;
  final String? today;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    String when(String date, String label) => keepWindowTogether('${dayLong(date, today: today)}, ${windowFromLabel(label)}');
    return Padding(
      padding: const EdgeInsets.only(bottom: IdSpace.s5),
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booked for', style: t.caption.copyWith(color: c.textMuted)),
            Text('Pickup ${when(order.pickupDate, order.pickupSlotLabel)}', style: t.title),
            Text('Delivery ${when(order.deliveryDate, order.deliverySlotLabel)}', style: t.bodyLg),
            const SizedBox(height: IdSpace.s1),
            Text(
              order.reschedulesRemaining == 1
                  ? 'You can change this time 1 more time.'
                  : 'You can change this time ${order.reschedulesRemaining} more times.',
              style: t.caption.copyWith(color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Under the delivery card: what happened to the delivery when the pickup moved.
class _DeliveryNote extends StatelessWidget {
  const _DeliveryNote({required this.schedule, required this.start});
  final Schedule schedule;
  final RescheduleStart start;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final delivery = schedule.delivery;
    final pickupMoved = slotKey(schedule.pickup!) != start.pickup;
    if (delivery == null || !pickupMoved) return const SizedBox.shrink();
    final kept = slotKey(delivery) == start.delivery;
    return Padding(
      padding: const EdgeInsets.only(top: IdSpace.s3),
      child: Semantics(
        liveRegion: true,
        child: kept
            ? Text('Your delivery time stays as booked.', style: t.caption.copyWith(color: c.textMuted))
            : Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(IdRadius.md)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.info, size: IdSize.iconMd, color: c.onPrimarySoft),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        keepWindowTogether('Your delivery moved to ${slotSummary(delivery, today: schedule.today)} so it comes after the new pickup. You can pick another time.'),
                        style: t.body,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.enabled, required this.onReview});
  final bool enabled;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(IdSpace.s5, IdSpace.s3, IdSpace.s5, IdSpace.s3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IdButton(label: 'Review change', expand: true, onPressed: onReview),
              if (!enabled) ...[
                const SizedBox(height: IdSpace.s2),
                Text(
                  'Pick a different time to continue.',
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

/// The order cannot be moved (any more): why, and who to call.
class _Closed extends ConsumerWidget {
  const _Closed({required this.order, required this.onBack});
  final OrderDto order;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final support = Support.of(ref);
    final used = order.reschedulesRemaining <= 0;
    final started = switch (order.status) {
      OrderStatus.pending || OrderStatus.pickupAssigned => false,
      _ => true,
    };
    final (title, body) = started
        ? (
            "The time can't be changed now",
            'The time can only be changed before your clothes are picked up. Call us if you need help.',
          )
        : used
        ? (
            "You've used all your changes",
            "You've already changed this time ${order.rescheduleCount.toInt() == 1 ? 'once' : '${order.rescheduleCount.toInt()} times'}. Call us if you need another change.",
          )
        : ("The time can't be changed", 'Call us if you need help with this order.');
    return StateView(
      icon: LucideIcons.calendarClock,
      title: title,
      body: body,
      primary: IdButton(
        label: 'Call us',
        icon: LucideIcons.phone,
        onPressed: () => Support.dial(support.phone, context: context, fallback: support),
      ),
      secondary: IdButton.text(label: 'Back to order', onPressed: onBack),
    );
  }
}

/// "Change your pickup time?": the change in full, then Confirm. Resolves with how it ended.
class _ConfirmSheet extends ConsumerStatefulWidget {
  const _ConfirmSheet({
    required this.order,
    required this.start,
    required this.pickup,
    required this.delivery,
    required this.today,
    required this.idempotencyKey,
  });

  final OrderDto order;
  final RescheduleStart start;
  final SlotOptionDto pickup;
  final SlotOptionDto delivery;
  final String? today;
  final String idempotencyKey;

  @override
  ConsumerState<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends ConsumerState<_ConfirmSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final o = widget.order;
    final dto = RescheduleOrderDto(
      pickupDate: widget.pickup.date,
      pickupSlot: widget.pickup.slot,
      deliveryDate: widget.delivery.date,
      deliverySlot: widget.delivery.slot,
    );
    try {
      await ref.read(orderRepositoryProvider).reschedule(o.id, dto, idempotencyKey: widget.idempotencyKey);
      ref.invalidate(orderProvider(o.id));
      refreshOrders(ref);
      // The order screen is behind this one: have the new time ready, so it never shows the old one for a moment.
      await ref.read(orderProvider(o.id).future).then((_) {}, onError: (_) {});
      if (mounted) Navigator.pop(context, _Outcome.done);
    } on ApiFailure catch (e) {
      if (rescheduleTimeRefused(e)) {
        ref.invalidate(pickupSlotsProvider);
        if (mounted) Navigator.pop(context, _Outcome.timesRefused);
        return;
      }
      if (rescheduleSlotFull(e)) {
        // Back to the picker with fresh windows: the full one now shows as Full. Nothing was changed or used up.
        ref.invalidate(pickupSlotsProvider);
        if (mounted) Navigator.pop(context, _Outcome.slotFull);
        return;
      }
      if (e.code == 'IDEMPOTENCY_KEY_REUSED' && mounted) {
        Navigator.pop(context, _Outcome.failed);
        return;
      }
      // The order moved on (picked up, or the last change was used elsewhere): show it as it is now.
      if (e.code == 'RESCHEDULE_NOT_ALLOWED' || e.code == 'RESCHEDULE_LIMIT') {
        ref.invalidate(orderProvider(o.id));
        refreshOrders(ref);
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _error = rescheduleFailureText(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final o = widget.order;
    final pickupMoved = slotKey(widget.pickup) != widget.start.pickup;
    final deliveryMoved = slotKey(widget.delivery) != widget.start.delivery;
    final left = o.reschedulesRemaining.toInt() - 1;
    final assigned = o.status == OrderStatus.pickupAssigned && pickupMoved;

    String was(String date, String label) => '${dayLong(date, today: widget.today)}, ${windowFromLabel(label)}';
    String now(SlotOptionDto s) => slotSummary(s, today: widget.today);

    Widget change(String label, String from, String to) => Padding(
      padding: const EdgeInsets.only(bottom: IdSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.caption.copyWith(color: c.textMuted)),
          Text(keepWindowTogether(to), style: t.title),
          Text(keepWindowTogether('Was $from'), style: t.body.copyWith(color: c.textMuted)),
        ],
      ),
    );

    return PopScope(
      canPop: !_busy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(pickupMoved ? 'Change your pickup time?' : 'Change your delivery time?', style: t.titleLg),
          ),
          const SizedBox(height: IdSpace.s1),
          Text('Your prices stay the same.', style: t.bodyLg.copyWith(color: c.textMuted)),
          const SizedBox(height: IdSpace.s4),
          if (pickupMoved) change('Pickup', was(o.pickupDate, o.pickupSlotLabel), now(widget.pickup)),
          if (deliveryMoved)
            change('Delivery', was(o.deliveryDate, o.deliverySlotLabel), now(widget.delivery))
          else if (pickupMoved)
            Padding(
              padding: const EdgeInsets.only(bottom: IdSpace.s3),
              child: Text(keepWindowTogether('Delivery stays ${now(widget.delivery)}.'), style: t.body.copyWith(color: c.textMuted)),
            ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(IdRadius.md)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: IdSize.iconMd, color: c.onPrimarySoft),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (assigned) ...[
                        Text("A partner is already assigned. We'll tell them and find a partner for the new time.", style: t.body),
                        const SizedBox(height: IdSpace.s2),
                      ],
                      Text(
                        left <= 0
                            ? 'This is your last change for this order.'
                            : left == 1
                            ? 'You can change it once more after this.'
                            : 'You can change it $left more times after this.',
                        style: t.body,
                      ),
                    ],
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
          IdButton(label: 'Confirm change', expand: true, loading: _busy, onPressed: _confirm),
          const SizedBox(height: IdSpace.s2),
          IdButton.outline(label: 'Keep current time', expand: true, onPressed: _busy ? null : () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
