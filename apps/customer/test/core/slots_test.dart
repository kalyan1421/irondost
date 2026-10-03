import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/core/slots.dart';
import 'package:irondost_customer/data/api_client.dart';

import '../helpers.dart';

void main() {
  test('names the windows the way customers say them', () {
    expect(slotName(TimeSlot.morning), 'Morning');
    expect(slotName(TimeSlot.noon), 'Afternoon');
    expect(slotName(TimeSlot.evening), 'Evening');
  });

  test('writes hours on India time, dropping the AM/PM that repeats', () {
    expect(slotWindow(testSlot(testToday, TimeSlot.morning)), '7 – 11 AM');
    expect(slotWindow(testSlot(testToday, TimeSlot.noon)), '11 AM – 4 PM');
    expect(slotWindow(testSlot(testToday, TimeSlot.evening)), '4 – 8 PM');
  });

  test('keeps half hours, and midnight and noon read as 12', () {
    SlotOptionDto at(int h, int m, int endH, int endM) => SlotOptionDto(
          date: testToday,
          slot: TimeSlot.morning,
          label: '',
          startsAt: DateTime.utc(2026, 10, 3, h, m).subtract(const Duration(hours: 5, minutes: 30)),
          endsAt: DateTime.utc(2026, 10, 3, endH, endM).subtract(const Duration(hours: 5, minutes: 30)),
          available: true,
        );
    expect(slotWindow(at(7, 30, 11, 0)), '7:30 – 11 AM');
    expect(slotWindow(at(11, 0, 12, 30)), '11 AM – 12:30 PM');
    expect(slotWindow(at(12, 0, 14, 0)), '12 – 2 PM');
  });

  test('formats dates as the API sends them, with no time-zone drift', () {
    expect(dayChipTop('2026-10-03', today: '2026-10-03'), 'Today');
    expect(dayChipTop('2026-10-04', today: '2026-10-03'), 'Sun');
    expect(dayChipNumber('2026-10-04'), '4');
    expect(dayLong('2026-10-05', today: '2026-10-03'), 'Mon 5 Oct');
    expect(slotSummary(testSlot('2026-10-04', TimeSlot.evening), today: testToday), 'Sun 4 Oct, 4 – 8 PM');
    expect(slotSummary(testSlot(testToday, TimeSlot.evening), today: testToday), 'Today, 4 – 8 PM');
  });

  test('reads an order\'s own window label the same way', () {
    expect(windowFromLabel('16:00–20:00'), '4 – 8 PM');
    expect(windowFromLabel('07:00-11:00'), '7 – 11 AM');
    expect(windowFromLabel('11:00–16:00'), '11 AM – 4 PM');
    expect(windowFromLabel('whenever'), 'whenever');
  });
}
