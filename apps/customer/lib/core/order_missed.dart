import '../data/api/export.dart';

/// The end of the order's pickup window, as an instant. The window label is IST, e.g. `11:00–16:00`.
/// Null when the label cannot be read.
DateTime? pickupWindowEnd(OrderDto o) {
  final times = RegExp(r'(\d{1,2}):(\d{2})').allMatches(o.pickupSlotLabel).toList();
  final match = times.length < 2 ? null : times.last;
  final day = DateTime.tryParse(o.pickupDate);
  if (match == null || day == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  // IST is UTC+5:30, so the window's end in UTC is 5½ hours earlier.
  return DateTime.utc(day.year, day.month, day.day, hour, minute).subtract(const Duration(hours: 5, minutes: 30));
}

/// The pickup window has ended and the clothes were never collected: a missed pickup, not a late one.
bool pickupMissed(OrderDto o, {DateTime? now}) {
  if (o.status != OrderStatus.pending && o.status != OrderStatus.pickupAssigned) return false;
  final end = pickupWindowEnd(o);
  return end != null && (now ?? DateTime.now()).toUtc().isAfter(end);
}
