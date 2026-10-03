import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/schedule/schedule.dart';

import '../helpers.dart';

void main() {
  Future<(ProviderContainer, FakeScheduleRepository)> open({FakeScheduleRepository? repo}) async {
    final fake = repo ?? FakeScheduleRepository();
    final container = ProviderContainer(overrides: [scheduleRepositoryProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);
    // Keep it alive like the screen does.
    container.listen(scheduleProvider, (_, _) {});
    return (container, fake);
  }

  Future<Schedule> settled(ProviderContainer c) async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
      final v = c.read(scheduleProvider);
      if (v.hasValue && (v.requireValue.pickup == null || (v.requireValue.deliverySlots?.hasValue ?? false))) return v.requireValue;
    }
    fail('schedule never settled');
  }

  test('starts on today with the earliest open window, and delivery the earliest after it', () async {
    final (c, _) = await open();
    final s = await settled(c);

    expect(s.today, testToday);
    expect(s.pickupDate, testToday);
    expect(s.pickupDates, testDays);
    expect(s.pickup!.slot, TimeSlot.evening);
    expect(s.delivery!.date, '2026-10-04');
    expect(s.delivery!.slot, TimeSlot.evening, reason: '20 hours after an 8 pm pickup is 4 pm');
    expect(s.deliveryIsEarliest, isTrue);
    expect(s.isComplete, isTrue);
  });

  test('another day opens on its earliest window; picking a window resets delivery', () async {
    final (c, repo) = await open();
    await settled(c);

    c.read(scheduleChoiceProvider.notifier).pickDate('2026-10-05');
    var s = await settled(c);
    expect(s.pickupDate, '2026-10-05');
    expect(s.pickup!.slot, TimeSlot.morning);
    expect(s.delivery!.date, '2026-10-06', reason: 'a 7–11 am pickup ends at 11, so 7 am the next morning is 20 hours on');
    expect(s.delivery!.slot, TimeSlot.morning);
    expect(repo.deliveryAsked.last, (date: '2026-10-05', slot: TimeSlot.morning));

    final evening = s.pickupWindows.last;
    c.read(scheduleChoiceProvider.notifier).pickPickup(evening);
    s = await settled(c);
    expect(s.pickup!.slot, TimeSlot.evening);
    expect(s.delivery!.date, '2026-10-06');
    expect(s.delivery!.slot, TimeSlot.evening);
  });

  test('a delivery the customer chose is kept, until the pickup changes', () async {
    final (c, _) = await open();
    var s = await settled(c);
    final later = s.deliverySlots!.value!.firstWhere((o) => o.date == '2026-10-06' && o.slot == TimeSlot.noon);

    c.read(scheduleChoiceProvider.notifier).pickDelivery(later);
    s = await settled(c);
    expect(slotKey(s.delivery!), slotKey(later));
    expect(s.deliveryIsEarliest, isFalse);

    c.read(scheduleChoiceProvider.notifier).pickPickup(s.pickupWindows.last);
    s = await settled(c);
    expect(slotKey(s.delivery!), (date: '2026-10-04', slot: TimeSlot.evening));
  });

  test('a window that has since closed is replaced by the earliest open one', () async {
    final (c, repo) = await open();
    var s = await settled(c);
    c.read(scheduleChoiceProvider.notifier).pickPickup(s.pickup!);
    await settled(c);

    // Time passes: tonight's window closes too.
    repo.closed.add((date: testToday, slot: TimeSlot.evening));
    c.invalidate(pickupSlotsProvider);
    s = await settled(c);
    expect(s.pickup, isNull, reason: 'nothing left today');
    expect(s.earliestPickup!.date, '2026-10-04');
    expect(s.earliestPickup!.slot, TimeSlot.morning);
    expect(s.isComplete, isFalse);
  });

  test('with today over, nothing is picked and the notice can offer the earliest', () async {
    final (c, _) = await open(repo: FakeScheduleRepository(closed: {(date: testToday, slot: TimeSlot.morning), (date: testToday, slot: TimeSlot.noon), (date: testToday, slot: TimeSlot.evening)}));
    var s = await settled(c);
    expect(s.pickup, isNull);
    expect(s.deliverySlots, isNull);
    expect(s.earliestPickup!.date, '2026-10-04');

    c.read(scheduleChoiceProvider.notifier).pickPickup(s.earliestPickup!);
    s = await settled(c);
    expect(s.pickupDate, '2026-10-04');
    expect(s.pickup!.slot, TimeSlot.morning);
    expect(s.isComplete, isTrue);
  });

  test('no windows at all is its own state, not an error', () async {
    final (c, _) = await open(repo: _Empty());
    await Future<void>.delayed(Duration.zero);
    expect(c.read(scheduleProvider).requireValue.isEmpty, isTrue);
  });

  test('a failing slot list is an error until retried', () async {
    final (c, repo) = await open(repo: FakeScheduleRepository()..pickupFailure = const ApiFailure(ApiFailureKind.offline));
    await Future<void>.delayed(Duration.zero);
    expect(c.read(scheduleProvider).hasError, isTrue);

    repo.pickupFailure = null;
    c.invalidate(pickupSlotsProvider);
    final s = await settled(c);
    expect(s.pickup, isNotNull);
  });

  test('a failing delivery list leaves the pickup chosen and delivery open', () async {
    final (c, _) = await open(repo: FakeScheduleRepository()..deliveryFailure = const ApiFailure(ApiFailureKind.server));
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    final s = c.read(scheduleProvider).requireValue;
    expect(s.pickup, isNotNull);
    expect(s.deliverySlots!.hasError, isTrue);
    expect(s.delivery, isNull);
    expect(s.isComplete, isFalse);
  });
}

class _Empty extends FakeScheduleRepository {
  @override
  Future<List<SlotOptionDto>> pickupSlots() async => const [];
}
