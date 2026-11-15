import '../data/api/export.dart';
import 'money.dart';
import 'slots.dart';
import 'quantities.dart';

/// "Shirt / T-shirt ×10 · Trousers / Jeans ×4 · Saree ×1": what is in an order, on one or two lines.
String itemsSummary(OrderDto order) =>
    [for (final i in order.items) i.unit == ItemUnit.piece ? '${i.name} ×${i.quantity.toInt()}' : '${i.name} · ${quantitySummary([(i.unit, i.quantity)])}']
        .join(' · ');

int pieceCount(OrderDto order) =>
    order.items.fold<num>(0, (a, i) => a + i.quantity).toInt();

/// "17 items".
String piecesLabel(OrderDto order) => quantitySummary(order.items.map((i) => (i.unit, i.quantity)));

/// Whether the customer can still pay: unpaid, not cancelled, and either online (the payment never finished)
/// or past pickup (cash is due at delivery, or can be paid online now).
bool canPayNow(OrderDto o) {
  if (o.adjustments?.any((a) => a.status == AdjustmentStatus.pendingCustomer) ?? false) return false;
  if (o.status == OrderStatus.cancelled || o.amountDuePaise <= 0) return false;
  if (o.paymentMethod == PaymentMethod.online) return true;
  return o.paidPaise > 0 || o.status.index >= OrderStatus.pickedUp.index;
}

/// The booking's payment choice is not evidence of how money was actually received.
String paidHow(OrderDto o) {
  final payments = o.payments ?? const <OrderPaymentDto>[];
  final cash = payments.any((p) => p.provider == PaymentProvider.cash);
  final online = payments.any((p) => p.provider == PaymentProvider.razorpay);
  if (cash && online) return 'Paid online and in cash';
  if (cash) return 'Paid in cash';
  if (online) return 'Paid online';
  return 'Payment received';
}

num completedRefundPaise(OrderDto o) => (o.refunds ?? const <RefundDto>[])
    .where((r) => r.status == RefundStatus.processed).fold<num>(0, (n, r) => n + r.amountPaise);

num pendingRefundPaise(OrderDto o) {
  if (o.refunds == null) return o.refundedPaise; // Older servers only expose the reserved total; never call it completed.
  return o.refunds!.where((r) => r.status == RefundStatus.pending).fold<num>(0, (n, r) => n + r.amountPaise);
}

String refundMethod(RefundMethod method) => switch (method) {
  RefundMethod.razorpay => 'Original online payment',
  RefundMethod.cash => 'Cash',
  RefundMethod.bankTransfer => 'Bank transfer',
  RefundMethod.$unknown => 'Refund',
};

String refundState(RefundStatus status) => switch (status) {
  RefundStatus.pending => 'Pending',
  RefundStatus.processed => 'Completed',
  RefundStatus.failed => 'Failed',
  RefundStatus.$unknown => 'Confirm with support',
};

/// Money paid that no refund, pending or completed, accounts for.
num unaccountedRefundPaise(OrderDto o) =>
    (o.paidPaise - completedRefundPaise(o) - pendingRefundPaise(o)).clamp(0, o.paidPaise);

/// The one thing refund rows cannot say: paid money with no refund behind it. Null when every rupee is accounted for.
String? refundGapNote(OrderDto o) {
  final gap = unaccountedRefundPaise(o);
  return gap > 0 ? '${rupees(gap)} has no confirmed refund. Contact support for the current status.' : null;
}

String refundSummary(OrderDto o) {
  final completed = completedRefundPaise(o);
  final pending = pendingRefundPaise(o);
  return [
    if (completed > 0) '${rupees(completed)} refunded.',
    if (pending > 0) '${rupees(pending)} refund pending.',
    ?refundGapNote(o),
  ].join(' ');
}

/// What happened to the money on a finished order: "Paid online", "Paid in cash", "Nothing charged", "₹120 refunded".
String settledNote(OrderDto o) {
  if (o.status == OrderStatus.cancelled) {
    if (o.paidPaise <= 0) return 'Nothing charged';
    return completedRefundPaise(o) >= o.paidPaise
        ? '${rupees(completedRefundPaise(o))} refunded'
        : 'Refund pending';
  }
  if (o.paymentStatus == PaymentStatus.paid) return paidHow(o);
  return o.amountDuePaise > 0 ? '${rupees(o.amountDuePaise)} due' : 'Paid';
}

/// Presentation only: identifies an elapsed delivery window without changing dispatch state.
bool deliveryEstimateMissed(OrderDto order, {DateTime? now}) {
  if (order.status == OrderStatus.pending || order.status == OrderStatus.pickupAssigned || order.status == OrderStatus.delivered ||
      order.status == OrderStatus.cancelled) {
    return false;
  }
  final current = now ?? DateTime.now();
  final match = RegExp(r'^\d{1,2}:\d{2}\s*[–-]\s*(\d{1,2}):(\d{2})$')
      .firstMatch(order.deliverySlotLabel.trim());
  if (match == null) return order.deliveryDate.compareTo(istToday(current)) < 0;
  final date = DateTime.tryParse('${order.deliveryDate}T00:00:00Z');
  if (date == null) return false;
  final end = date
      .add(Duration(hours: int.parse(match[1]!), minutes: int.parse(match[2]!)))
      .subtract(const Duration(hours: 5, minutes: 30));
  return !current.toUtc().isBefore(end);
}
