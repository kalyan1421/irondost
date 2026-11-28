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

/// The five customer-facing steps for an order that is still moving: Booked, Picked up, Cleaning,
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
          ? [if (o.pickedUpAt != null) time(o.pickedUpAt!), '${piecesLabel(o)} counted'].join(' · ')
          : '${dayLong(o.pickupDate, today: now)}, ${windowFromLabel(o.pickupSlotLabel)}',
    ),
    // Washing, ironing or dry cleaning. Leaving it (ready for delivery) is the owner's hand check of every piece.
    TimelineStep(
      'Cleaning',
      state(3),
      switch (o.status) {
        OrderStatus.processing => 'Being cleaned',
        OrderStatus.readyForDelivery => 'Checked by hand · ready for delivery',
        _ => step > 3 && readyAt != null ? 'Checked by hand ${time(readyAt)}' : null,
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

/// What the customer can do at the stage the order is at.
enum StageAction {
  /// Before pickup: tell the workshop how to treat the clothes.
  careNote,

  /// A new total is waiting for the customer's OK.
  approvePrice,

  /// After delivery: something wrong with an item.
  reportIssue,
}

/// One line on what is happening to the order right now, in the customer's words.
String nowLine(OrderDto o) => switch (o.status) {
      OrderStatus.pending => o.dispatchFailedAt != null
          ? "We're still finding a partner for your pickup"
          : "We're lining up a partner to collect your clothes",
      OrderStatus.pickupAssigned => 'Your partner is on the way to collect your clothes',
      OrderStatus.pickedUp => 'Your clothes are on their way to our workshop',
      OrderStatus.processing => 'Your clothes are being washed, ironed and cared for',
      OrderStatus.readyForDelivery => 'Every piece has been checked by hand and packed',
      OrderStatus.deliveryAssigned => 'A partner will bring your clothes back soon',
      OrderStatus.outForDelivery => 'Your clothes are on their way back to you',
      OrderStatus.delivered => 'Delivered: fresh clothes, ready to wear',
      OrderStatus.cancelled => 'This order was cancelled',
      OrderStatus.$unknown => "We're updating this order",
    };

/// The action that fits where the order is: approving a new price comes first whenever one waits, then a care note
/// before pickup, then reporting a problem after delivery.
StageAction? stageAction(OrderDto o) {
  if (o.adjustments?.any((a) => a.status == AdjustmentStatus.pendingCustomer) ?? false) return StageAction.approvePrice;
  if (o.status == OrderStatus.pending || o.status == OrderStatus.pickupAssigned) return StageAction.careNote;
  if (o.status == OrderStatus.delivered) return StageAction.reportIssue;
  return null;
}
