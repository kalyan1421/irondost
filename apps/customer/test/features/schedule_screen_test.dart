import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/schedule/schedule.dart';
import 'package:irondost_customer/features/schedule/schedule_screen.dart';
import 'package:irondost_customer/features/startup/startup.dart';

import '../helpers.dart';

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

  Future<(ProviderContainer, FakeScheduleRepository)> pump(WidgetTester tester, {FakeScheduleRepository? repo}) async {
    final fake = repo ?? FakeScheduleRepository();
    // A phone, so nothing a customer can reach is below the fold.
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      themed(
        const ScheduleScreen(),
        overrides: [
          scheduleRepositoryProvider.overrideWithValue(fake),
          startupProvider.overrideWith((ref) async => const Startup(config: config, installedVersion: '2.0.0')),
        ],
      ),
    );
    await tester.pumpAndSettle();
    return (ProviderScope.containerOf(tester.element(find.byType(Scaffold).first)), fake);
  }

  FilledButton continueButton(WidgetTester tester) => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'));

  testWidgets('shows today with the closed windows dimmed and the earliest open one chosen', (tester) async {
    await pump(tester);

    expect(find.text('When should we collect?'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('SUN'), findsOneWidget);
    expect(find.bySemanticsLabel('Morning, 7 – 11 AM · Closed'), findsOneWidget);
    expect(find.bySemanticsLabel('Afternoon, 11 AM – 4 PM · Closed'), findsOneWidget);
    expect(find.bySemanticsLabel('Evening, 4 – 8 PM'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('Sun 4 Oct, 4 – 8 PM'), findsOneWidget);
    expect(find.text('Earliest after ironing'), findsOneWidget);
    expect(continueButton(tester).onPressed, isNotNull);
  });

  testWidgets('another day lists that day\'s windows and moves delivery along', (tester) async {
    final (_, repo) = await pump(tester);

    await tester.tap(find.text('MON'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Morning, 7 – 11 AM'), findsOneWidget);
    expect(find.text('Tue 6 Oct, 7 – 11 AM'), findsOneWidget);
    expect(repo.deliveryAsked.last, (date: '2026-10-05', slot: TimeSlot.morning));
  });

  testWidgets('tapping a window selects it, and a closed one does nothing', (tester) async {
    final (container, _) = await pump(tester);
    await tester.tap(find.text('MON'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Afternoon, 11 AM – 4 PM'));
    await tester.pumpAndSettle();
    expect(container.read(scheduleProvider).requireValue.pickup!.slot, TimeSlot.noon);
    expect(find.text('Tue 6 Oct, 4 – 8 PM'), findsOneWidget, reason: 'a pickup ending at 4 pm is delivered from 12 noon next day: the evening window');

    await tester.tap(find.text('TODAY'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Morning, 7 – 11 AM · Closed'));
    await tester.pumpAndSettle();
    expect(container.read(scheduleProvider).requireValue.pickup!.slot, TimeSlot.evening, reason: 'still the open window');
  });

  testWidgets('Change opens the delivery windows; too-soon ones are dimmed and a later one can be taken', (tester) async {
    final (container, _) = await pump(tester);

    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    expect(find.text('Delivery time'), findsOneWidget);
    expect(find.textContaining('Ironing takes about 20 hours'), findsOneWidget);
    expect(find.bySemanticsLabel('Morning, 7 – 11 AM · Too soon'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('TUE')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Afternoon, 11 AM – 4 PM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Delivery time'), findsNothing);
    expect(find.text('Tue 6 Oct, 11 AM – 4 PM'), findsOneWidget);
    expect(find.text('Your choice'), findsOneWidget);
    expect(container.read(scheduleProvider).requireValue.deliveryIsEarliest, isFalse);
  });

  testWidgets('with today over it says so, offers the earliest, and Continue waits for a choice', (tester) async {
    final today = {for (final s in [TimeSlot.morning, TimeSlot.noon, TimeSlot.evening]) (date: testToday, slot: s)};
    await pump(tester, repo: FakeScheduleRepository(closed: today));

    expect(find.textContaining("Today's pickups have closed. The earliest is Sun 4 Oct, 7 – 11 AM."), findsOneWidget);
    expect(find.text('Delivery'), findsNothing);
    expect(continueButton(tester).onPressed, isNull);

    await tester.tap(find.text('Pick Sun, 7 – 11 AM'));
    await tester.pumpAndSettle();
    expect(find.textContaining("Today's pickups have closed"), findsNothing);
    expect(find.text('Delivery'), findsOneWidget);
    expect(continueButton(tester).onPressed, isNotNull);
  });

  testWidgets('a failed slot list says so and Try again loads it', (tester) async {
    final repo = FakeScheduleRepository()..pickupFailure = const ApiFailure(ApiFailureKind.offline);
    await pump(tester, repo: repo);
    expect(find.text("Couldn't load pickup times"), findsOneWidget);
    expect(find.textContaining("You're offline"), findsOneWidget);
    expect(continueButton(tester).onPressed, isNull);

    repo.pickupFailure = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('When should we collect?'), findsOneWidget);
    expect(continueButton(tester).onPressed, isNotNull);
  });

  testWidgets('a failed delivery list keeps the pickup and lets the customer retry', (tester) async {
    final repo = FakeScheduleRepository()..deliveryFailure = const ApiFailure(ApiFailureKind.server);
    await pump(tester, repo: repo);
    expect(find.text("Couldn't load delivery times."), findsOneWidget);
    expect(continueButton(tester).onPressed, isNull);

    repo.deliveryFailure = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Sun 4 Oct, 4 – 8 PM'), findsOneWidget);
    expect(continueButton(tester).onPressed, isNotNull);
  });

  testWidgets('no windows at all offers a call', (tester) async {
    await pump(tester, repo: _Empty());
    expect(find.text('No pickup times open right now'), findsOneWidget);
    expect(find.textContaining('Call +91 90632 90012'), findsOneWidget);
  });
}

class _Empty extends FakeScheduleRepository {
  @override
  Future<List<SlotOptionDto>> pickupSlots() async => const [];
}
