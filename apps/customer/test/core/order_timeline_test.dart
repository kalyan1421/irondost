import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/core/order_timeline.dart';
import 'package:irondost_customer/data/api_client.dart';

import '../helpers.dart';

void main() {
  OrderEventDto event(OrderStatus to, DateTime at) => OrderEventDto(fromStatus: null, toStatus: to, actorRole: null, note: null, createdAt: at);

  List<ProgressState> states(List<TimelineStep> steps) => [for (final s in steps) s.state];

  test('a new order: booked is current, the rest wait, and say when they are due', () {
    final steps = buildTimeline(testOrder(pickupDate: testToday, deliveryDate: '2026-10-04'), today: testToday);

    expect(steps.map((s) => s.title), ['Booked', 'Picked up', 'Ironing', 'Out for delivery', 'Delivered']);
    expect(states(steps), [ProgressState.current, ProgressState.future, ProgressState.future, ProgressState.future, ProgressState.future]);
    expect(steps[0].meta, 'Finding a partner near you');
    expect(steps[1].meta, 'Today, 4 – 8 PM');
    expect(steps[4].meta, 'Sun 4 Oct, 4 – 8 PM');
  });

  test('a pickup that could not find a partner says since when', () {
    final steps = buildTimeline(testOrder(dispatchFailedAt: DateTime.utc(2026, 10, 3, 9, 30)), today: testToday);
    expect(steps[0].meta, 'Looking for a partner since Sat 3 Oct, 5:30 PM');
  });

  test('a partner assigned, before pickup', () {
    final steps = buildTimeline(testOrder(status: OrderStatus.pickupAssigned), today: testToday);
    expect(steps[0].state, ProgressState.current);
    expect(steps[0].meta, 'Partner assigned');
  });

  test('being ironed: booked and picked up are done, with the count and the time', () {
    final steps = buildTimeline(
      testOrder(status: OrderStatus.processing, pickedUpAt: DateTime.utc(2026, 10, 1, 12, 10), pieces: 12),
      today: testToday,
    );
    expect(states(steps), [ProgressState.done, ProgressState.done, ProgressState.current, ProgressState.future, ProgressState.future]);
    expect(steps[1].meta, 'Thu 1 Oct, 5:40 PM · 12 items counted');
    expect(steps[2].meta, 'Being ironed');
  });

  test('out for delivery: names who left and when, and when the ironing was ready', () {
    final steps = buildTimeline(
      testOrder(
        status: OrderStatus.outForDelivery,
        pickedUpAt: DateTime.utc(2026, 10, 1, 12, 10),
        events: [event(OrderStatus.readyForDelivery, DateTime.utc(2026, 10, 3, 5, 50)), event(OrderStatus.outForDelivery, DateTime.utc(2026, 10, 3, 10, 40))],
        deliveryDriver: const PersonRefDto(id: 'd1', name: 'Ravi Kumar', phone: '+919876500001'),
      ),
      today: testToday,
    );
    expect(states(steps), [ProgressState.done, ProgressState.done, ProgressState.done, ProgressState.current, ProgressState.future]);
    expect(steps[2].meta, 'Ready Sat 3 Oct, 11:20 AM');
    expect(steps[3].meta, 'Ravi left at 4:10 PM');
  });

  test('delivered: every step is done and the last says when', () {
    final steps = buildTimeline(
      testOrder(status: OrderStatus.delivered, pickedUpAt: DateTime.utc(2026, 10, 1, 12, 10), deliveredAt: DateTime.utc(2026, 10, 3, 12, 2)),
      today: testToday,
    );
    expect(states(steps).every((s) => s == ProgressState.done), isTrue);
    expect(steps[4].meta, 'Sat 3 Oct, 5:32 PM');
  });
}
