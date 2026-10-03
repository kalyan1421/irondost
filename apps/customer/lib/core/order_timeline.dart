import '../data/api/export.dart';
import 'order_status.dart';
import 'order_text.dart';
import 'slots.dart';

enum ProgressState { done, current, future }

class TimelineStep {
  const TimelineStep(this.title, this.state, [this.meta]);

  final String title;
  final ProgressState state;
  final String? meta;
}

/// The five customer-facing steps for an order that is still moving: Booked, Picked up, Ironing,
/// Out for delivery, Delivered. Cancelled orders have no timeline.
List<TimelineStep> buildTimeline(OrderDto o, {String? today}) {
  final step = o.status.timelineStep;
  final now = today ?? istToday();
  DateTime? when(OrderStatus s) => o.events?.where((e) => e.toStatus == s).map((e) => e.createdAt).firstOrNull;
  String time(DateTime t) => istDateTimeLabel(t);

  ProgressState state(int n) => n < step || step == 5 ? ProgressState.done : (n == step ? ProgressState.current : ProgressState.future);

  final partner = (o.status == OrderStatus.outForDelivery ? o.deliveryDriver : null)?.name?.split(' ').first;
  final outAt = when(OrderStatus.outForDelivery);
  final readyAt = when(OrderStatus.readyForDelivery);

  return [
    TimelineStep(
      'Booked',
      state(1),
      switch (o.status) {
        OrderStatus.pending => o.dispatchFailedAt != null ? 'Looking for a partner since ${time(o.createdAt)}' : 'Finding a partner near you',
        OrderStatus.pickupAssigned => 'Partner assigned',
        _ => time(o.createdAt),
      },
    ),
    TimelineStep(
      'Picked up',
      state(2),
      step >= 2
          ? [if (o.pickedUpAt != null) time(o.pickedUpAt!), '${pieceCount(o)} items counted'].join(' · ')
          : '${dayLong(o.pickupDate, today: now)}, ${windowFromLabel(o.pickupSlotLabel)}',
    ),
    TimelineStep(
      'Ironing',
      state(3),
      switch (o.status) {
        OrderStatus.processing => 'Being ironed',
        OrderStatus.readyForDelivery => 'Ready for delivery',
        _ => step > 3 && readyAt != null ? 'Ready ${time(readyAt)}' : null,
      },
    ),
    TimelineStep(
      'Out for delivery',
      state(4),
      switch (o.status) {
        OrderStatus.deliveryAssigned => 'Partner assigned',
        OrderStatus.outForDelivery => outAt == null ? 'On the way' : '${partner ?? 'Your partner'} left at ${time(outAt).split(', ').last}',
        _ => step > 4 && outAt != null ? time(outAt) : null,
      },
    ),
    TimelineStep(
      'Delivered',
      state(5),
      step == 5 && o.deliveredAt != null ? time(o.deliveredAt!) : '${dayLong(o.deliveryDate, today: now)}, ${windowFromLabel(o.deliverySlotLabel)}',
    ),
  ];
}
