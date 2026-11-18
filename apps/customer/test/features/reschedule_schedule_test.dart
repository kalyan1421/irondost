import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/schedule/schedule.dart';

import '../helpers.dart';

/// The picker state while changing an order's time: it starts on the order's windows, keeps its delivery while that is
/// still allowed, and never touches the booking in progress.
void main() {
  // Booked Monday 5 Oct morning, delivery Wednesday 7 Oct morning (the fake's rules: 20 hours after the pickup ends).
  const start = (
    orderId: 'o-1',
    pickup: (date: '2026-10-05', slot: TimeSlot.morning),
    delivery: (date: '2026-10-07', slot: TimeSlot.morning),
  );

  Future<(ProviderContainer, FakeScheduleRepository)> open() async {
    final fake = FakeScheduleRepository();
    final container = ProviderContainer(overrides: [scheduleRepositoryProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);
    container.listen(rescheduleScheduleProvider(start), (_, _) {});
    return (container, fake);
  }

  Future<Schedule> settled(ProviderContainer c) async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
      final v = c.read(rescheduleScheduleProvider(start));
      if (v.hasValue && (v.requireValue.pickup == null || (v.requireValue.deliverySlots?.hasValue ?? false))) return v.requireValue;
    }
    fail('schedule never settled');
  }

  test('starts on the windows the order has now', () async {
    final (c, _) = await open();
    final s = await settled(c);

    expect(s.pickupDate, '2026-10-05');
    expect((s.pickup!.date, s.pickup!.slot), ('2026-10-05', TimeSlot.morning));
    expect((s.delivery!.date, s.delivery!.slot), ('2026-10-07', TimeSlot.morning));
    expect(s.isComplete, isTrue);
  });

  test('another pickup keeps the delivery while it is still allowed after it', () async {
    final (c, _) = await open();
    await settled(c);

    c.read(rescheduleChoiceProvider(start).notifier).pickPickup(testSlot('2026-10-06', TimeSlot.morning));
    final s = await settled(c);
    expect((s.pickup!.date, s.pickup!.slot), ('2026-10-06', TimeSlot.morning));
    expect((s.delivery!.date, s.delivery!.slot), ('2026-10-07', TimeSlot.morning), reason: '7 am the next day is 20 hours after an 11 am end');
  });

  test('a pickup that leaves the delivery too soon gives it the earliest allowed time instead', () async {
    final (c, _) = await open();
    await settled(c);

    c.read(rescheduleChoiceProvider(start).notifier).pickPickup(testSlot('2026-10-06', TimeSlot.evening));
    final s = await settled(c);
    expect((s.delivery!.date, s.delivery!.slot), ('2026-10-07', TimeSlot.evening), reason: '8 pm plus 20 hours is 4 pm on the 7th');
  });

  test('another day starts on its earliest open window; going back to the order\'s own day selects its own window', () async {
    final (c, _) = await open();
    await settled(c);
    final picks = c.read(rescheduleChoiceProvider(start).notifier);

    picks.pickDate('2026-10-06');
    var s = await settled(c);
    expect((s.pickupDate, s.pickup!.slot), ('2026-10-06', TimeSlot.morning));
    expect(s.delivery!.date, '2026-10-07');

    picks.pickDate('2026-10-05');
    s = await settled(c);
    expect((s.pickup!.date, s.pickup!.slot), ('2026-10-05', TimeSlot.morning));
  });

  test('a delivery the customer picked is used', () async {
    final (c, _) = await open();
    final before = await settled(c);

    c.read(rescheduleChoiceProvider(start).notifier).pickDelivery(before.deliverySlots!.requireValue.firstWhere((s) => s.date == '2026-10-07' && s.slot == TimeSlot.evening));
    final s = await settled(c);
    expect((s.delivery!.date, s.delivery!.slot), ('2026-10-07', TimeSlot.evening));
    expect((s.pickup!.date, s.pickup!.slot), ('2026-10-05', TimeSlot.morning));
  });

  test('is separate from the booking in progress, and from another order', () async {
    final (c, _) = await open();
    await settled(c);
    c.read(rescheduleChoiceProvider(start).notifier).pickDate('2026-10-06');
    await settled(c);

    expect(c.read(scheduleChoiceProvider).pickupDate, isNull);
    const other = (orderId: 'o-2', pickup: (date: '2026-10-04', slot: TimeSlot.evening), delivery: (date: '2026-10-06', slot: TimeSlot.evening));
    expect(c.read(rescheduleChoiceProvider(other)).pickupDate, '2026-10-04');
  });

  test('a booked window that has closed is not kept: another open window on that day stands in', () async {
    final closed = FakeScheduleRepository(closed: {(date: '2026-10-05', slot: TimeSlot.morning)});
    final c = ProviderContainer(overrides: [scheduleRepositoryProvider.overrideWithValue(closed)]);
    addTearDown(c.dispose);
    c.listen(rescheduleScheduleProvider(start), (_, _) {});
    final s = await settled(c);
    expect((s.pickup!.date, s.pickup!.slot), ('2026-10-05', TimeSlot.noon));
  });
}
