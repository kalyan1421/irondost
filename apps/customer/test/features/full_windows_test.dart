import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/core/slots.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/orders/reschedule_order.dart';
import 'package:irondost_customer/features/schedule/schedule.dart';
import 'package:irondost_customer/features/schedule/schedule_screen.dart';
import 'package:irondost_customer/features/startup/startup.dart';

import '../helpers.dart';

/// A pickup window with no place left: the API lists it as `available: false` with the reason `FULL`, and the pickers show it
/// disabled with the word Full (a closed window is just closed).
const _absent = Object();

void main() {
  const config = PublicConfigDto(
    appName: 'IronDost',
    supportPhone: '+919063290012',
    supportEmail: null,
    minOrderPaise: 0,
    deliveryFeePaise: 0,
    freeDeliveryAbovePaise: null,
    minTurnaroundHours: 20,
    maxAdvanceDays: 30,
    slots: [],
  );
  const mon = '2026-10-05';

  group('the slot options', () {
    test('a full window is not available and says why; a closed one has no reason', () {
      final full = testSlot(mon, TimeSlot.noon, available: false, reason: SlotUnavailableReason.full);
      final closed = testSlot(mon, TimeSlot.morning, available: false);
      expect((full.available, full.isFull), (false, true));
      expect((closed.available, closed.isFull), (false, false));
      expect(testSlot(mon, TimeSlot.evening).isFull, isFalse);
    });

    test('reads the reason from the API: FULL, none (an older API), and one this app does not know', () {
      Map<String, Object?> json({Object? reason = _absent}) => {
        'date': mon,
        'slot': 'MORNING',
        'label': '07:00–11:00',
        'startsAt': '2026-10-05T01:30:00.000Z',
        'endsAt': '2026-10-05T05:30:00.000Z',
        'available': false,
        if (reason != _absent) 'reason': reason,
      };
      expect(SlotOptionDto.fromJson(json(reason: 'FULL')).isFull, isTrue);
      expect(SlotOptionDto.fromJson(json(reason: null)).isFull, isFalse);
      expect(SlotOptionDto.fromJson(json()).isFull, isFalse, reason: 'an older API sends no reason at all');
      final unknown = SlotOptionDto.fromJson(json(reason: 'SOMETHING_NEW'));
      expect(unknown.isFull, isFalse);
      expect(unknown.reason, SlotUnavailableReason.$unknown, reason: 'a reason the app does not know does not break reading the list');
    });
  });

  group('booking: the pickup picker', () {
    Future<(ProviderContainer, FakeScheduleRepository)> pump(WidgetTester tester, FakeScheduleRepository repo, {double textScale = 1}) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 844 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        themed(
          const ScheduleScreen(),
          textScale: textScale,
          overrides: [
            scheduleRepositoryProvider.overrideWithValue(repo),
            startupProvider.overrideWith((ref) async => const Startup(config: config, installedVersion: '2.0.0')),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return (ProviderScope.containerOf(tester.element(find.byType(Scaffold).first)), repo);
    }

    FilledButton continueButton(WidgetTester tester) => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'));

    testWidgets('a full window stays listed, disabled, with the word Full, between the open ones', (tester) async {
      final (container, _) = await pump(tester, FakeScheduleRepository(full: {(date: mon, slot: TimeSlot.noon)}));
      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Morning, 7 – 11 AM'), findsOneWidget);
      expect(find.bySemanticsLabel('Afternoon, 11 AM – 4 PM · Full'), findsOneWidget);
      expect(find.bySemanticsLabel('Evening, 4 – 8 PM'), findsOneWidget);
      expect(find.textContaining('closed'), findsNothing, reason: 'full is not closed');
      expect(tester.getSemantics(find.bySemanticsLabel('Afternoon, 11 AM – 4 PM · Full')).flagsCollection.isEnabled.name, 'isFalse');

      await tester.tap(find.bySemanticsLabel('Afternoon, 11 AM – 4 PM · Full'));
      await tester.pumpAndSettle();
      expect(container.read(scheduleProvider).requireValue.pickup!.slot, TimeSlot.morning, reason: 'tapping a full window selects nothing');
    });

    testWidgets('is never chosen by default: the earliest open window is', (tester) async {
      final (container, _) = await pump(tester, FakeScheduleRepository(full: {(date: mon, slot: TimeSlot.morning)}, todayOver: false));
      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();
      expect(container.read(scheduleProvider).requireValue.pickup!.slot, TimeSlot.noon);
      expect(continueButton(tester).onPressed, isNotNull);
    });

    testWidgets('closed and full on the same day are named separately', (tester) async {
      // Today: morning closed, afternoon full, evening open.
      await pump(tester, FakeScheduleRepository(closed: {(date: testToday, slot: TimeSlot.morning)}, full: {(date: testToday, slot: TimeSlot.noon)}));
      expect(find.text('Morning is closed for today.'), findsOneWidget);
      expect(find.bySemanticsLabel('Afternoon, 11 AM – 4 PM · Full'), findsOneWidget);
      expect(find.bySemanticsLabel('Evening, 4 – 8 PM'), findsOneWidget);
    });

    testWidgets('a day with every window full says so, lists them all as Full, and offers the earliest open one', (tester) async {
      final all = {for (final s in [TimeSlot.morning, TimeSlot.noon, TimeSlot.evening]) (date: mon, slot: s)};
      await pump(tester, FakeScheduleRepository(full: all));
      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Morning, 7 – 11 AM · Full'), findsOneWidget);
      expect(find.bySemanticsLabel('Afternoon, 11 AM – 4 PM · Full'), findsOneWidget);
      expect(find.bySemanticsLabel('Evening, 4 – 8 PM · Full'), findsOneWidget);
      expect(find.textContaining('Every pickup time on Mon 5 Oct is full.'), findsOneWidget);
      expect(find.textContaining("Today's pickups have closed"), findsNothing);
      expect(find.text('Delivery'), findsNothing);
      expect(continueButton(tester).onPressed, isNull);

      await tester.tap(find.textContaining('Pick '));
      await tester.pumpAndSettle();
      expect(find.text('Delivery'), findsOneWidget);
      expect(continueButton(tester).onPressed, isNotNull);
    });

    testWidgets('today with the rest closed and the last window full says so', (tester) async {
      await pump(tester, FakeScheduleRepository(full: {(date: testToday, slot: TimeSlot.evening)}));
      expect(find.textContaining("Today's pickups are full or closed."), findsOneWidget);
      expect(find.bySemanticsLabel('Evening, 4 – 8 PM · Full'), findsOneWidget);
      expect(find.bySemanticsLabel('Morning, 7 – 11 AM · Closed'), findsOneWidget);
      expect(continueButton(tester).onPressed, isNull);
    });

    testWidgets('a window that fills up while the screen is open shows as Full after the list is read again', (tester) async {
      final repo = FakeScheduleRepository();
      final (container, _) = await pump(tester, repo);
      expect(container.read(scheduleProvider).requireValue.pickup!.slot, TimeSlot.evening);

      repo.full.add((date: testToday, slot: TimeSlot.evening));
      container.invalidate(pickupSlotsProvider);
      await tester.pumpAndSettle();
      expect(container.read(scheduleProvider).requireValue.pickup, isNull, reason: 'the chosen window is full now, so it is not kept');
      expect(find.bySemanticsLabel('Evening, 4 – 8 PM · Full'), findsOneWidget);
      expect(continueButton(tester).onPressed, isNull);
    });

    testWidgets('reads at 200% text without overflowing', (tester) async {
      await pump(tester, FakeScheduleRepository(full: {(date: testToday, slot: TimeSlot.evening)}), textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('changing an order\'s time', () {
    // Booked Monday 5 Oct morning, delivery Wednesday 7 Oct morning.
    const start = (
      orderId: 'o-1',
      pickup: (date: mon, slot: TimeSlot.morning),
      delivery: (date: '2026-10-07', slot: TimeSlot.morning),
    );

    Future<Schedule> settled(ProviderContainer c) async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
        final v = c.read(rescheduleScheduleProvider(start));
        if (v.hasValue && (v.requireValue.pickup == null || (v.requireValue.deliverySlots?.hasValue ?? false))) return v.requireValue;
      }
      fail('schedule never settled');
    }

    test('the window the order already holds is never Full for its own customer, even when the API counts it as full', () async {
      final fake = FakeScheduleRepository(full: {(date: mon, slot: TimeSlot.morning), (date: '2026-10-06', slot: TimeSlot.morning)});
      final c = ProviderContainer(overrides: [scheduleRepositoryProvider.overrideWithValue(fake)]);
      addTearDown(c.dispose);
      c.listen(rescheduleScheduleProvider(start), (_, _) {});
      final s = await settled(c);

      expect((s.pickup!.date, s.pickup!.slot), (mon, TimeSlot.morning), reason: 'it starts where the order is');
      expect(s.pickupWindows.firstWhere((w) => w.slot == TimeSlot.morning).available, isTrue);
      expect(s.isComplete, isTrue);

      // Another full window is still full.
      c.read(rescheduleChoiceProvider(start).notifier).pickDate('2026-10-06');
      final next = await settled(c);
      expect(next.pickupWindows.firstWhere((w) => w.slot == TimeSlot.morning).isFull, isTrue);
      expect(next.pickup!.slot, TimeSlot.noon, reason: 'never defaults to a full window');
    });

    test('a booking in progress sees the same window as Full', () async {
      final fake = FakeScheduleRepository(full: {(date: mon, slot: TimeSlot.morning)});
      final c = ProviderContainer(overrides: [scheduleRepositoryProvider.overrideWithValue(fake)]);
      addTearDown(c.dispose);
      c.listen(scheduleProvider, (_, _) {});
      c.read(scheduleChoiceProvider.notifier).pickDate(mon);
      for (var i = 0; i < 20 && !(c.read(scheduleProvider).value?.pickup != null); i++) {
        await Future<void>.delayed(Duration.zero);
      }
      final s = c.read(scheduleProvider).requireValue;
      expect(s.pickupWindows.firstWhere((w) => w.slot == TimeSlot.morning).isFull, isTrue);
      expect(s.pickup!.slot, TimeSlot.noon);
    });
  });

  group('changing an order\'s time: the screen', () {
    final d = [for (var i = 0; i < 5; i++) DateTime.parse('${istToday()}T00:00:00Z').add(Duration(days: i)).toIso8601String().substring(0, 10)];
    String chip(int i) => dayChipTop(d[i], today: d[0]);
    final booked = testOrder(
      pickupDate: d[1],
      pickupSlot: TimeSlot.morning,
      pickupLabel: '07:00–11:00',
      deliveryDate: d[3],
      deliverySlot: TimeSlot.morning,
      deliveryLabel: '07:00–11:00',
      canReschedule: true,
    );

    Future<(FakeOrderRepository, FakeScheduleRepository)> pump(WidgetTester tester, {Set<SlotKey> full = const {}}) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 844 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final orders = FakeOrderRepository()..orders[booked.id] = booked;
      final slots = FakeScheduleRepository(days: d, todayOver: false, full: {...full});
      final router = testRouter({Routes.orderReschedule: () => RescheduleScreen(orderId: booked.id, initial: booked), Routes.orders: () => const Text('ORDERS PAGE')}, initial: Routes.reschedule(booked.id));
      await tester.pumpWidget(
        themedRouter(
          router,
          overrides: [
            orderRepositoryProvider.overrideWithValue(orders),
            scheduleRepositoryProvider.overrideWithValue(slots),
            startupProvider.overrideWith((ref) async => const Startup(config: config, installedVersion: '2.0.0')),
            ...await basketOverrides(),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return (orders, slots);
    }

    testWidgets('shows another full window as Full and cannot be chosen, while the order\'s own window stays selected', (tester) async {
      await pump(tester, full: {(date: d[1], slot: TimeSlot.morning), (date: d[2], slot: TimeSlot.morning)});

      final own = tester.getSemantics(find.bySemanticsLabel('Morning, 7 – 11 AM'));
      expect(own.flagsCollection.isChecked, CheckedState.isTrue, reason: 'its own window is its own, full or not');
      await tester.tap(find.text(chip(2)));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Morning, 7 – 11 AM · Full'), findsOneWidget);
      expect(find.bySemanticsLabel('Afternoon, 11 AM – 4 PM'), findsOneWidget);
    });

    testWidgets('a window that filled up while the customer was choosing: back to the picker with a clear note, and nothing changed', (tester) async {
      final (orders, slots) = await pump(tester);
      orders.rescheduleFailures.add(const ApiFailure(ApiFailureKind.rejected, statusCode: 409, code: 'SLOT_FULL'));
      await tester.tap(find.text(chip(2)));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Morning, 7 – 11 AM'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Review change'));
      await tester.pumpAndSettle();
      final asked = slots.pickupAsked;
      // What the API says now: that window is full.
      slots.full.add((date: d[2], slot: TimeSlot.morning));

      await tester.tap(find.text('Confirm change'));
      await tester.pumpAndSettle();

      expect(find.text('Change your pickup time?'), findsNothing, reason: 'the sheet closes');
      expect(find.text('That pickup time just filled up. Please pick another. Your current time is unchanged.'), findsOneWidget);
      expect(slots.pickupAsked, greaterThan(asked), reason: 'the windows are read again');
      expect(find.bySemanticsLabel('Morning, 7 – 11 AM · Full'), findsOneWidget, reason: 'so the full one shows as Full');
      expect(find.text('Booked for'), findsOneWidget);
      expect(orders.orders[booked.id]!.pickupDate, d[1]);
    });
  });
}
