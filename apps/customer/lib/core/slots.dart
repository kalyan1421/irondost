import 'package:intl/intl.dart';

import '../data/api/export.dart';

/// "Morning", "Afternoon", "Evening".
String slotName(TimeSlot slot) => switch (slot) {
      TimeSlot.morning => 'Morning',
      TimeSlot.noon => 'Afternoon',
      TimeSlot.evening => 'Evening',
      TimeSlot.$unknown => 'Slot',
    };

/// Slots run on India time whatever the phone's zone is.
DateTime _ist(DateTime instant) => instant.toUtc().add(const Duration(hours: 5, minutes: 30));

String _clock(int hour, int minute) => minute == 0 ? '${hour % 12 == 0 ? 12 : hour % 12}' : '${hour % 12 == 0 ? 12 : hour % 12}:${minute.toString().padLeft(2, '0')}';
String _meridiem(int hour) => hour < 12 ? 'AM' : 'PM';

String _window(int startHour, int startMinute, int endHour, int endMinute) {
  final sameHalf = _meridiem(startHour) == _meridiem(endHour);
  return '${_clock(startHour, startMinute)}${sameHalf ? '' : ' ${_meridiem(startHour)}'} – ${_clock(endHour, endMinute)} ${_meridiem(endHour)}';
}

/// The window as people say it: "7 – 11 AM", "11 AM – 4 PM", "4 – 8 PM", "7:30 – 11 AM".
String slotWindow(SlotOptionDto slot) {
  final start = _ist(slot.startsAt);
  final end = _ist(slot.endsAt);
  return _window(start.hour, start.minute, end.hour, end.minute);
}

/// The same from an order's label, "16:00–20:00" (the API's own text). Anything else comes back as sent.
String windowFromLabel(String label) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})\s*[–-]\s*(\d{1,2}):(\d{2})$').firstMatch(label.trim());
  if (m == null) return label;
  return _window(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!), int.parse(m[4]!));
}

/// "2026-10-03" as a calendar date. No time zone is involved: the API sends IST calendar days.
DateTime _day(String isoDate) => DateTime.parse(isoDate);

/// The date chip's top line: "Today", else "Sat".
String dayChipTop(String isoDate, {required String today}) => isoDate == today ? 'Today' : DateFormat('E').format(_day(isoDate));

/// The date chip's number: "3".
String dayChipNumber(String isoDate) => '${_day(isoDate).day}';

/// "Sat 3 Oct" ("Today 3 Oct" for [today]).
String dayLong(String isoDate, {String? today}) => isoDate == today ? 'Today' : DateFormat('EEE d MMM').format(_day(isoDate));

/// "Sat 3 Oct, 4 – 8 PM".
String slotSummary(SlotOptionDto slot, {String? today}) => '${dayLong(slot.date, today: today)}, ${slotWindow(slot)}';

/// Today's date in India, "2026-10-03", from the phone's clock. Only for wording ("today"); the API decides what is bookable.
String istToday([DateTime? now]) => DateFormat('yyyy-MM-dd').format((now ?? DateTime.now()).toUtc().add(const Duration(hours: 5, minutes: 30)));

/// "Thu 1 Oct" for an instant, on India time.
String istDayLabel(DateTime instant) => DateFormat('EEE d MMM').format(_ist(instant));

/// "Thu 1 Oct, 9:12 AM" for an instant, on India time.
String istDateTimeLabel(DateTime instant) {
  final t = _ist(instant);
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '${DateFormat('EEE d MMM').format(t)}, $hour:${t.minute.toString().padLeft(2, '0')} ${_meridiem(t.hour)}';
}

/// For the middle of a sentence: "today", "tomorrow", else "Sat 3 Oct". [today] is the India date, "2026-10-03".
String dayPhrase(String isoDate, {required String today}) {
  if (isoDate == today) return 'today';
  final tomorrow = DateFormat('yyyy-MM-dd').format(DateTime.parse(today).add(const Duration(days: 1)));
  return isoDate == tomorrow ? 'tomorrow' : dayLong(isoDate);
}

/// The time on a notification: "3:52 PM" today, "Thu, 5:41 PM" this week, "26 Sep" before that. India time.
String notificationTime(DateTime at, {DateTime? now}) {
  final t = _ist(at);
  final n = _ist(now ?? DateTime.now());
  final days = DateTime.utc(n.year, n.month, n.day).difference(DateTime.utc(t.year, t.month, t.day)).inDays;
  final clock = '${t.hour % 12 == 0 ? 12 : t.hour % 12}:${t.minute.toString().padLeft(2, '0')} ${_meridiem(t.hour)}';
  if (days <= 0) return clock;
  if (days < 7) return '${DateFormat('EEE').format(t)}, $clock';
  return DateFormat('d MMM').format(t);
}

/// Whether [at] is the same India calendar day as [now].
bool isTodayIst(DateTime at, {DateTime? now}) {
  final t = _ist(at);
  final n = _ist(now ?? DateTime.now());
  return t.year == n.year && t.month == n.month && t.day == n.day;
}
