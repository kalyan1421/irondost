import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/core/order_missed.dart';
import 'package:irondost_customer/data/api_client.dart';

import '../helpers.dart';

void main() {
  final order = testOrder(pickupDate: '2026-11-04', pickupLabel: '11:00–16:00');

  test('the window ends at its IST end time', () {
    expect(pickupWindowEnd(order), DateTime.utc(2026, 11, 4, 10, 30));
  });

  test('missed only once the window has ended and nothing was collected', () {
    expect(pickupMissed(order, now: DateTime.utc(2026, 11, 4, 10, 29)), isFalse);
    expect(pickupMissed(order, now: DateTime.utc(2026, 11, 4, 10, 31)), isTrue);
    expect(pickupMissed(testOrder(status: OrderStatus.pickupAssigned, pickupDate: '2026-11-04', pickupLabel: '11:00–16:00'), now: DateTime.utc(2026, 11, 28)), isTrue);
    expect(pickupMissed(testOrder(status: OrderStatus.pickedUp, pickupDate: '2026-11-04', pickupLabel: '11:00–16:00'), now: DateTime.utc(2026, 11, 28)), isFalse);
  });

  test('an unreadable label is never called missed', () {
    expect(pickupMissed(testOrder(pickupLabel: 'Evening'), now: DateTime.utc(2030)), isFalse);
  });
}
