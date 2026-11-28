import 'dart:async';
import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/core/slots.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/orders/order_detail_screen.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/orders/orders_list.dart';
import 'package:irondost_customer/features/orders/reschedule_order.dart';
import 'package:irondost_customer/features/schedule/schedule.dart';
import 'package:irondost_customer/features/schedule/schedule_screen.dart' show ScheduleLoading;
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
  const ravi = PersonRefDto(id: 'd1', name: 'Ravi K.', phone: '+919876500001');

  // Days from the real today (India), so nothing depends on the date the tests run: d[0] is "Today" in the picker.
  final d = [for (var i = 0; i < 5; i++) DateTime.parse('${istToday()}T00:00:00Z').add(Duration(days: i)).toIso8601String().substring(0, 10)];
  String chip(int i) => dayChipTop(d[i], today: d[0]);
  String long(int i) => dayLong(d[i]);
  FakeScheduleRepository fakeSlots({Set<SlotKey>? closed}) => FakeScheduleRepository(days: d, todayOver: false, closed: closed);

  /// Booked for d[1] morning, delivery d[3] morning: still valid after d[1] or d[2] morning, too soon after d[2] evening.
  OrderDto booked({int rescheduleCount = 0, bool canReschedule = true, OrderStatus status = OrderStatus.pending, PersonRefDto? driver, DateTime? dispatchFailedAt}) => testOrder(
    status: status,
    pickupDriver: driver,
    dispatchFailedAt: dispatchFailedAt,
    pickupDate: d[1],
    pickupSlot: TimeSlot.morning,
    pickupLabel: '07:00–11:00',
    deliveryDate: d[3],
    deliverySlot: TimeSlot.morning,
    deliveryLabel: '07:00–11:00',
    rescheduleCount: rescheduleCount,
    canReschedule: canReschedule,
  );

  Future<(GoRouter, FakeOrderRepository, FakeScheduleRepository)> pump(
    WidgetTester tester,
    OrderDto order, {
    String initial = '',
    FakeScheduleRepository? schedule,
    FakeOrderRepository? repo,
    double textScale = 1,
    double width = 390,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view
      ..physicalSize = Size(width * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final orders = repo ?? FakeOrderRepository();
    orders.orders[order.id] = order;
    final slots = schedule ?? fakeSlots();
    final router = testRouter(
      {
        Routes.orders: () => const Text('ORDERS PAGE'),
        Routes.orderDetail: () => Consumer(builder: (_, ref, _) => OrderDetailScreen(orderId: order.id, initial: order)),
        Routes.orderReschedule: () => RescheduleScreen(orderId: order.id, initial: order),
      },
      initial: initial.isEmpty ? Routes.order(order.id) : initial,
    );
    await tester.pumpWidget(
      themedRouter(
        router,
        brightness: brightness,
        textScale: textScale,
        overrides: [
          orderRepositoryProvider.overrideWithValue(orders),
          scheduleRepositoryProvider.overrideWithValue(slots),
          startupProvider.overrideWith((ref) async => const Startup(config: config, installedVersion: '2.0.0')),
          ...await basketOverrides(),
        ],
      ),
    );
    await tester.pumpAndSettle();
    return (router, orders, slots);
  }

  Finder window(String label) => find.bySemanticsLabel(label);
  Finder reviewButton() => find.widgetWithText(FilledButton, 'Review change');
  Future<void> openScreen(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Change pickup time'), 200, scrollable: find.byType(Scrollable).first);
    // Clear of the footer buttons, which sit over the bottom of the list.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change pickup time'));
    await tester.pumpAndSettle();
  }

  group('the row on the order', () {
    testWidgets('is offered while the API says the time can change, with the changes left', (tester) async {
      await pump(tester, booked());
      await tester.scrollUntilVisible(find.text('Change pickup time'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Change pickup time'), findsOneWidget);
      expect(find.text('2 changes left'), findsOneWidget);
    });

    testWidgets('says "1 change left" after one change', (tester) async {
      await pump(tester, booked(rescheduleCount: 1));
      await tester.scrollUntilVisible(find.text('Change pickup time'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('1 change left'), findsOneWidget);
    });

    testWidgets('is not there once the API says no (picked up, all changes used, finished)', (tester) async {
      await pump(tester, booked(canReschedule: false, status: OrderStatus.pickedUp, rescheduleCount: 1));
      expect(find.text('Change pickup time'), findsNothing);
      expect(find.text('Report a problem', skipOffstage: false), findsOneWidget);
    });

    testWidgets('a late pickup offers it next to Call us and Cancel', (tester) async {
      await pump(tester, booked(dispatchFailedAt: DateTime.utc(2026, 10, 3, 9)));
      expect(find.textContaining('All our partners nearby are busy'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Change time'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Change time'));
      await tester.pumpAndSettle();
      expect(find.text('Booked for'), findsOneWidget);
    });

    testWidgets('opens the screen', (tester) async {
      await pump(tester, booked());
      await openScreen(tester);
      expect(find.text('Booked for'), findsOneWidget);
      expect(find.text('When should we collect?'), findsOneWidget);
    });
  });

  group('the screen', () {
    testWidgets('starts on what the order has now, with nothing to confirm yet', (tester) async {
      await pump(tester, booked(), initial: Routes.reschedule('o-1'));

      expect(find.text('Change pickup time'), findsOneWidget); // the app bar
      expect(find.text('Booked for'), findsOneWidget);
      expect(find.textContaining('Pickup ${long(1)}, 7'), findsOneWidget);
      expect(find.textContaining('Delivery ${long(3)}, 7'), findsOneWidget);
      expect(find.text('You can change this time 2 more times.'), findsOneWidget);
      expect(window('Morning, 7 – 11 AM'), findsOneWidget);
      final morning = tester.getSemantics(window('Morning, 7 – 11 AM'));
      expect(morning.flagsCollection.isChecked, CheckedState.isTrue, reason: 'the current window is selected');
      expect(tester.widget<FilledButton>(reviewButton()).onPressed, isNull);
      expect(find.text('Pick a different time to continue.'), findsOneWidget);
    });

    testWidgets('says how many changes are left, including the last one', (tester) async {
      await pump(tester, booked(rescheduleCount: 1), initial: Routes.reschedule('o-1'));
      expect(find.text('You can change this time 1 more time.'), findsOneWidget);
    });

    testWidgets('keeps the delivery while it is still allowed after the new pickup', (tester) async {
      await pump(tester, booked(), initial: Routes.reschedule('o-1'));

      await tester.tap(find.text(chip(2)));
      await tester.pumpAndSettle();
      await tester.tap(window('Morning, 7 – 11 AM'));
      await tester.pumpAndSettle();

      expect(find.text('Your delivery time stays as booked.', skipOffstage: false), findsOneWidget);
      expect(find.text('${long(3)}, 7 – 11 AM', skipOffstage: false), findsOneWidget);
      expect(tester.widget<FilledButton>(reviewButton()).onPressed, isNotNull);
    });

    testWidgets('moves the delivery to the earliest allowed one when the old one is too soon, and says so', (tester) async {
      await pump(tester, booked(), initial: Routes.reschedule('o-1'));

      await tester.tap(find.text(chip(2)));
      await tester.pumpAndSettle();
      await tester.tap(window('Evening, 4 – 8 PM'));
      await tester.pumpAndSettle();

      expect(find.textContaining(keepWindowTogether('Your delivery moved to ${long(3)}, 4 – 8 PM so it comes after the new pickup'), skipOffstage: false), findsOneWidget);
      expect(find.text('Your delivery time stays as booked.', skipOffstage: false), findsNothing);
    });

    testWidgets('going back to the order\'s own day selects its own window again, and nothing is left to confirm', (tester) async {
      await pump(tester, booked(), initial: Routes.reschedule('o-1'));
      await tester.tap(find.text(chip(2)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(chip(1)));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(reviewButton()).onPressed, isNull);
    });

    testWidgets('does not touch the booking in progress', (tester) async {
      final (router, _, _) = await pump(tester, booked(), initial: Routes.reschedule('o-1'));
      await tester.tap(find.text(chip(2)));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
      expect(container.read(scheduleChoiceProvider).pickupDate, isNull);
      expect(router, isNotNull);
    });

    testWidgets('can change only the delivery', (tester) async {
      final (_, repo, _) = await pump(tester, booked(), initial: Routes.reschedule('o-1'));

      await tester.scrollUntilVisible(find.text('Change'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      expect(find.text('Delivery time'), findsOneWidget);
      await tester.tap(find.text(chip(4)).last);
      await tester.pumpAndSettle();
      await tester.tap(window('Evening, 4 – 8 PM').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      await tester.tap(reviewButton());
      await tester.pumpAndSettle();
      expect(find.text('Change your delivery time?'), findsOneWidget);
      await tester.tap(find.text('Confirm change'));
      await tester.pumpAndSettle();

      final (_, dto, _) = repo.rescheduled.single;
      expect((dto.pickupDate, dto.pickupSlot), (d[1], TimeSlot.morning));
      expect((dto.deliveryDate, dto.deliverySlot), (d[4], TimeSlot.evening));
      expect(find.text('Delivery time changed'), findsOneWidget);
    });
  });

  group('confirming', () {
    Future<void> chooseMondayMorning(WidgetTester tester) async {
      await tester.tap(find.text(chip(2)));
      await tester.pumpAndSettle();
      await tester.tap(window('Morning, 7 – 11 AM'));
      await tester.pumpAndSettle();
      await tester.tap(reviewButton());
      await tester.pumpAndSettle();
    }

    testWidgets('shows the whole change first, and keeping the current time sends nothing', (tester) async {
      final (_, repo, _) = await pump(tester, booked(), initial: Routes.reschedule('o-1'));
      await chooseMondayMorning(tester);

      expect(find.text('Change your pickup time?'), findsOneWidget);
      expect(find.text('Your prices stay the same.'), findsOneWidget);
      expect(find.text('Pickup'), findsOneWidget);
      expect(find.textContaining('${long(2)}, 7'), findsWidgets);
      expect(find.textContaining('Was ${long(1)}, 7'), findsOneWidget);
      expect(find.textContaining('Delivery stays ${long(3)}, 7'), findsOneWidget);
      expect(find.text('You can change it once more after this.'), findsOneWidget);

      await tester.tap(find.text('Keep current time'));
      await tester.pumpAndSettle();
      expect(repo.rescheduled, isEmpty);
      expect(find.text('Change your pickup time?'), findsNothing);
      expect(find.text('Booked for'), findsOneWidget, reason: 'still on the picker');
    });

    testWidgets('on the last change it says so', (tester) async {
      await pump(tester, booked(rescheduleCount: 1), initial: Routes.reschedule('o-1'));
      await chooseMondayMorning(tester);
      expect(find.text('This is your last change for this order.'), findsOneWidget);
    });

    testWidgets('tells the customer a partner is already assigned, and that they will be told', (tester) async {
      await pump(tester, booked(status: OrderStatus.pickupAssigned, driver: ravi), initial: Routes.reschedule('o-1'));
      await chooseMondayMorning(tester);
      expect(find.textContaining("A partner is already assigned. We'll tell them and find a partner for the new time."), findsOneWidget);
    });

    testWidgets('sends the new times with a key, goes back to the order, which shows the new time, and refreshes the lists', (tester) async {
      final (router, repo, _) = await pump(tester, booked(), initial: Routes.reschedule('o-1'));
      // The order screen is behind: it was opened first.
      router.go(Routes.order('o-1'));
      await tester.pumpAndSettle();
      await openScreen(tester);
      final gets = repo.getCount;
      // The Orders tab is open somewhere behind: both its lists must be read again.
      final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
      container.listen(ordersListProvider(Scope.active), (_, _) {});
      container.listen(ordersListProvider(Scope.past), (_, _) {});
      await tester.pump();
      final listsBefore = repo.listAsked.length;
      await chooseMondayMorning(tester);

      await tester.tap(find.text('Confirm change'));
      await tester.pumpAndSettle();

      final (id, dto, key) = repo.rescheduled.single;
      expect(id, 'o-1');
      expect((dto.pickupDate, dto.pickupSlot, dto.deliveryDate, dto.deliverySlot), (d[2], TimeSlot.morning, d[3], TimeSlot.morning));
      expect(key, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      // Back on the order, which has been read again, with a note that it worked and the new time in the hero.
      expect(find.text('Pickup changed'), findsNothing);
      expect(find.text('Pickup time changed'), findsOneWidget);
      expect(find.text('Booked for'), findsNothing);
      expect(repo.getCount, greaterThan(gets));
      expect(find.textContaining('Estimated · ${long(2)}'), findsOneWidget);
      expect(find.text('1 change left'), findsOneWidget);
      expect(repo.listAsked.skip(listsBefore).map((a) => a.$1), containsAll([Scope.active, Scope.past]));
    });

    testWidgets('shows a spinner while it is sending and ignores another tap', (tester) async {
      final (_, repo, _) = await pump(tester, booked(), initial: Routes.reschedule('o-1'));
      repo.holdReschedule = Completer<void>();
      await chooseMondayMorning(tester);

      await tester.tap(find.text('Confirm change'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Keep current time').hitTestable(), findsOneWidget);
      expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Keep current time')).onPressed, isNull);
      await tester.tap(find.byType(CircularProgressIndicator), warnIfMissed: false);
      await tester.pump();
      expect(repo.rescheduled, hasLength(1));

      repo.holdReschedule!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Pickup time changed'), findsOneWidget);
    });

    testWidgets('offline: says nothing changed, and trying again reuses the key so one change is never used twice', (tester) async {
      final (_, repo, _) = await pump(tester, booked(), initial: Routes.reschedule('o-1'));
      repo.rescheduleFailures.add(const ApiFailure(ApiFailureKind.offline));
      await chooseMondayMorning(tester);

      await tester.tap(find.text('Confirm change'));
      await tester.pumpAndSettle();
      expect(find.text("You're offline. Nothing was changed. Check your connection and try again."), findsOneWidget);
      expect(find.text('Change your pickup time?'), findsOneWidget, reason: 'the sheet stays for another go');

      await tester.tap(find.text('Confirm change'));
      await tester.pumpAndSettle();
      expect(repo.rescheduled, hasLength(2));
      expect(repo.rescheduled[1].$3, repo.rescheduled[0].$3, reason: 'the same change keeps its key');
      expect(find.text('Pickup time changed'), findsOneWidget);
    });

    testWidgets('a different choice gets its own key', (tester) async {
      final (_, repo, _) = await pump(tester, booked(), initial: Routes.reschedule('o-1'));
      repo.rescheduleFailures.add(const ApiFailure(ApiFailureKind.timeout));
      await chooseMondayMorning(tester);
      await tester.tap(find.text('Confirm change'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep current time'));
      await tester.pumpAndSettle();

      await tester.tap(window('Afternoon, 11 AM – 4 PM'));
      await tester.pumpAndSettle();
      await tester.tap(reviewButton());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm change'));
      await tester.pumpAndSettle();

      expect(repo.rescheduled, hasLength(2));
      expect(repo.rescheduled[1].$3, isNot(repo.rescheduled[0].$3));
    });

    testWidgets('a time that closed meanwhile: back to the picker with a note, and the windows are read again', (tester) async {
      final (_, repo, slots) = await pump(tester, booked(), initial: Routes.reschedule('o-1'));
      repo.rescheduleFailures.add(const ApiFailure(ApiFailureKind.rejected, statusCode: 400, code: 'PICKUP_SLOT_CLOSED'));
      await chooseMondayMorning(tester);
      final asked = slots.pickupAsked;

      await tester.tap(find.text('Confirm change'));
      await tester.pumpAndSettle();

      expect(find.text('Change your pickup time?'), findsNothing);
      expect(find.text("That time isn't available any more. Please pick another."), findsOneWidget);
      expect(slots.pickupAsked, greaterThan(asked));
      expect(find.text('Booked for'), findsOneWidget);
    });

    testWidgets('the last change used on another phone: the message, then the closed screen', (tester) async {
      final (_, repo, _) = await pump(tester, booked(), initial: Routes.reschedule('o-1'));
      repo.rescheduleFailures.add(const ApiFailure(ApiFailureKind.rejected, statusCode: 409, code: 'RESCHEDULE_LIMIT'));
      await chooseMondayMorning(tester);
      // What the API would now say about the order.
      repo.orders['o-1'] = booked(rescheduleCount: 2, canReschedule: false);

      await tester.tap(find.text('Confirm change'));
      await tester.pumpAndSettle();
      expect(find.text("You've used all the changes for this order. Call us if you need another."), findsOneWidget);

      await tester.tap(find.text('Keep current time'));
      await tester.pumpAndSettle();
      expect(find.text("You've used all your changes"), findsOneWidget);
      expect(find.text('Call us'), findsOneWidget);
    });

    testWidgets('picked up meanwhile: says so', (tester) async {
      final (_, repo, _) = await pump(tester, booked(), initial: Routes.reschedule('o-1'));
      repo.rescheduleFailures.add(const ApiFailure(ApiFailureKind.rejected, statusCode: 409, code: 'RESCHEDULE_NOT_ALLOWED'));
      await chooseMondayMorning(tester);
      repo.orders['o-1'] = booked(canReschedule: false, status: OrderStatus.pickedUp);

      await tester.tap(find.text('Confirm change'));
      await tester.pumpAndSettle();
      expect(find.textContaining("This order can't be changed any more"), findsOneWidget);
      await tester.tap(find.text('Keep current time'));
      await tester.pumpAndSettle();
      expect(find.text("The time can't be changed now"), findsOneWidget);
    });

    testWidgets('any other failure is said plainly, and can be tried again', (tester) async {
      final (_, repo, _) = await pump(tester, booked(), initial: Routes.reschedule('o-1'));
      repo.rescheduleFailures.add(const ApiFailure(ApiFailureKind.server, statusCode: 500));
      await chooseMondayMorning(tester);
      await tester.tap(find.text('Confirm change'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't change the time. Please try again."), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm change')).onPressed, isNotNull);
    });
  });

  group('states', () {
    testWidgets('while the times load', (tester) async {
      final slots = fakeSlots();
      await tester.pumpWidget(const SizedBox());
      tester.view
        ..physicalSize = const Size(390 * 3, 844 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final hold = Completer<List<SlotOptionDto>>();
      await tester.pumpWidget(
        themedRouter(
          testRouter({Routes.orderReschedule: () => RescheduleScreen(orderId: 'o-1', initial: booked())}, initial: Routes.reschedule('o-1')),
          overrides: [
            orderRepositoryProvider.overrideWithValue(FakeOrderRepository()..orders['o-1'] = booked()),
            scheduleRepositoryProvider.overrideWithValue(_Slow(slots, hold.future)),
            startupProvider.overrideWith((ref) async => const Startup(config: config, installedVersion: '2.0.0')),
            ...await basketOverrides(),
          ],
        ),
      );
      await tester.pump();
      expect(find.byType(ScheduleLoading), findsOneWidget);
      expect(tester.widget<FilledButton>(reviewButton()).onPressed, isNull);
    });

    testWidgets('offline: says so and Try again loads the times', (tester) async {
      final slots = fakeSlots()..pickupFailure = const ApiFailure(ApiFailureKind.offline);
      await pump(tester, booked(), initial: Routes.reschedule('o-1'), schedule: slots);

      expect(find.text("Couldn't load pickup times"), findsOneWidget);
      expect(find.text("You're offline. Check your connection and try again."), findsOneWidget);
      expect(tester.widget<FilledButton>(reviewButton()).onPressed, isNull);

      slots.pickupFailure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('When should we collect?'), findsOneWidget);
    });

    testWidgets('the order itself cannot be loaded: a way to try again', (tester) async {
      final repo = FakeOrderRepository()..getFailure = const ApiFailure(ApiFailureKind.offline);
      tester.view
        ..physicalSize = const Size(390 * 3, 844 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        themedRouter(
          testRouter({Routes.orderReschedule: () => const RescheduleScreen(orderId: 'o-1')}, initial: Routes.reschedule('o-1')),
          overrides: [
            orderRepositoryProvider.overrideWithValue(repo),
            scheduleRepositoryProvider.overrideWithValue(fakeSlots()),
            ...await basketOverrides(),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("You're offline. Check your connection and try again."), findsOneWidget);
      repo.getFailure = null;
      repo.orders['o-1'] = booked();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Booked for'), findsOneWidget);
    });

    testWidgets('after pickup: why not, and Call us', (tester) async {
      await pump(tester, booked(canReschedule: false, status: OrderStatus.pickedUp), initial: Routes.reschedule('o-1'));
      expect(find.text("The time can't be changed now"), findsOneWidget);
      expect(find.text('Call us'), findsOneWidget);
      expect(find.text('Back to order'), findsOneWidget);
      expect(find.text('Review change'), findsNothing);
    });

    testWidgets('all changes used: says so', (tester) async {
      await pump(tester, booked(canReschedule: false, rescheduleCount: 2), initial: Routes.reschedule('o-1'));
      expect(find.text("You've used all your changes"), findsOneWidget);
      expect(find.textContaining("You've already changed this time 2 times."), findsOneWidget);
    });

    testWidgets('every window closed: the notice for it, and nothing to confirm', (tester) async {
      final slots = fakeSlots(closed: {for (final day in d) for (final s in [TimeSlot.morning, TimeSlot.noon, TimeSlot.evening]) (date: day, slot: s)});
      await pump(tester, booked(), initial: Routes.reschedule('o-1'), schedule: slots);
      await tester.tap(find.text(chip(2)));
      await tester.pumpAndSettle();
      expect(find.textContaining('No pickups are open on'), findsOneWidget);
      expect(tester.widget<FilledButton>(reviewButton()).onPressed, isNull);
    });

    testWidgets('the API lists no windows at all: the usual notice with a number to call', (tester) async {
      await pump(tester, booked(), initial: Routes.reschedule('o-1'), schedule: _Empty());
      expect(find.text('No pickup times open right now'), findsOneWidget);
      expect(find.textContaining('Call +91'), findsOneWidget);
      expect(tester.widget<FilledButton>(reviewButton()).onPressed, isNull);
    });
  });

  group('large text and dark', () {
    for (final (width, scale) in [(320.0, 2.0), (390.0, 2.0)]) {
      testWidgets('the picker and the confirmation fit at ${width.toInt()} dp, text ${scale}x', (tester) async {
        final problems = <String>[];
        final original = FlutterError.onError;
        FlutterError.onError = (details) => problems.add(details.toString().split('\n').first);
        try {
          await pump(tester, booked(status: OrderStatus.pickupAssigned, driver: ravi), initial: Routes.reschedule('o-1'), textScale: scale, width: width);
          final list = find.byType(Scrollable).first;
          await tester.scrollUntilVisible(find.text(chip(2)), 100, scrollable: list);
          await tester.tap(find.text(chip(2)));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(window('Evening, 4 – 8 PM'), 100, scrollable: list);
          await tester.tap(window('Evening, 4 – 8 PM'));
          await tester.pumpAndSettle();
          await tester.tap(reviewButton());
          await tester.pumpAndSettle();
          expect(find.text('Confirm change'), findsOneWidget);
        } finally {
          FlutterError.onError = original;
        }
        expect(problems, isEmpty);
      });
    }

    testWidgets('the order row and the closed screen fit at 320 dp, text 2x, in dark', (tester) async {
      final problems = <String>[];
      final original = FlutterError.onError;
      FlutterError.onError = (details) => problems.add(details.toString().split('\n').first);
      try {
        await pump(tester, booked(), textScale: 2, width: 320, brightness: Brightness.dark);
        await pump(tester, booked(canReschedule: false, rescheduleCount: 2), initial: Routes.reschedule('o-1'), textScale: 2, width: 320, brightness: Brightness.dark);
      } finally {
        FlutterError.onError = original;
      }
      expect(problems, isEmpty);
    });
  });

  group('wording and helpers', () {
    test('changes left', () {
      expect(changesLeft(2), '2 changes left');
      expect(changesLeft(1), '1 change left');
    });

    test('failure text says what happened and what to do', () {
      expect(rescheduleFailureText(const ApiFailure(ApiFailureKind.timeout)), contains('Nothing was changed'));
      expect(rescheduleFailureText(const ApiFailure(ApiFailureKind.rejected, code: 'RESCHEDULE_LIMIT')), contains('Call us'));
      expect(rescheduleFailureText(const ApiFailure(ApiFailureKind.rejected, code: 'RESCHEDULE_NOT_ALLOWED')), contains('Call us'));
      expect(rescheduleFailureText(const ApiFailure(ApiFailureKind.server)), "Couldn't change the time. Please try again.");
    });

    test('the times the API refuses are the ones the picker can fix', () {
      for (final code in ['PICKUP_SLOT_CLOSED', 'PICKUP_TOO_FAR_AHEAD', 'DELIVERY_TOO_SOON', 'DELIVERY_TOO_FAR_AHEAD', 'INVALID_DATE']) {
        expect(rescheduleTimeRefused(ApiFailure(ApiFailureKind.rejected, code: code)), isTrue, reason: code);
      }
      expect(rescheduleTimeRefused(const ApiFailure(ApiFailureKind.rejected, code: 'RESCHEDULE_LIMIT')), isFalse);
    });
  });
}

/// A schedule whose pickup windows arrive when the test says.
class _Slow implements ScheduleRepository {
  _Slow(this.inner, this.pickup);
  final ScheduleRepository inner;
  final Future<List<SlotOptionDto>> pickup;

  @override
  Future<List<SlotOptionDto>> pickupSlots() => pickup;

  @override
  Future<List<SlotOptionDto>> deliverySlots(String pickupDate, TimeSlot pickupSlot) => inner.deliverySlots(pickupDate, pickupSlot);
}

/// The API lists no pickup windows.
class _Empty extends FakeScheduleRepository {
  @override
  Future<List<SlotOptionDto>> pickupSlots() async => [];

  @override
  Future<List<SlotOptionDto>> deliverySlots(String pickupDate, TimeSlot pickupSlot) async => [];
}
