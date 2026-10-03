import '../data/api/export.dart';
import 'money.dart';

/// "Shirt / T-shirt ×10 · Trousers / Jeans ×4 · Saree ×1": what is in an order, on one or two lines.
String itemsSummary(OrderDto order) => [for (final i in order.items) '${i.name} ×${i.quantity.toInt()}'].join(' · ');

int pieceCount(OrderDto order) => order.items.fold<num>(0, (a, i) => a + i.quantity).toInt();

/// "17 items".
String piecesLabel(OrderDto order) {
  final n = pieceCount(order);
  return '$n ${n == 1 ? 'item' : 'items'}';
}

/// Whether the customer can still pay: unpaid, not cancelled, and either online (the payment never finished)
/// or past pickup (cash is due at delivery, or can be paid online now).
bool canPayNow(OrderDto o) {
  if (o.status == OrderStatus.cancelled || o.amountDuePaise <= 0) return false;
  if (o.paymentMethod == PaymentMethod.online) return true;
  return o.paidPaise > 0 || o.status.index >= OrderStatus.pickedUp.index;
}

/// How a paid order was paid: "Paid online" or "Paid in cash". Cash is only collected at delivery, so a cash-on-delivery
/// order that is paid before it is delivered must have been paid online.
String paidHow(OrderDto o) => o.paymentMethod == PaymentMethod.cod && o.status == OrderStatus.delivered ? 'Paid in cash' : 'Paid online';

/// What happened to the money on a finished order: "Paid online", "Paid in cash", "Nothing charged", "₹120 refunded".
String settledNote(OrderDto o) {
  if (o.status == OrderStatus.cancelled) {
    if (o.paidPaise <= 0) return 'Nothing charged';
    return o.refundedPaise >= o.paidPaise ? '${rupees(o.refundedPaise)} refunded' : 'Refund on its way';
  }
  if (o.paymentStatus == PaymentStatus.paid) return paidHow(o);
  return o.amountDuePaise > 0 ? '${rupees(o.amountDuePaise)} due' : 'Paid';
}
