import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/core/order_text.dart';
import 'package:irondost_customer/data/api_client.dart';

import '../helpers.dart';

void main() {
  OrderDto order({OrderStatus status = OrderStatus.pending, PaymentMethod method = PaymentMethod.cod, PaymentStatus paid = PaymentStatus.unpaid, int paidPaise = 0, int total = 24800, int refunded = 0}) =>
      testOrder(status: status, method: method, paymentStatus: paid, paidPaise: paidPaise, totalPaise: total, refundedPaise: refunded);

  group('paidHow', () {
    test('an online order was paid online', () => expect(paidHow(order(method: PaymentMethod.online, paid: PaymentStatus.paid, paidPaise: 24800)), 'Paid online'));

    test('a cash order paid before it was delivered was paid online, since cash is only taken at the door', () {
      expect(paidHow(order(status: OrderStatus.processing, paid: PaymentStatus.paid, paidPaise: 24800)), 'Paid online');
    });

    test('a cash order that was delivered and paid was paid in cash', () {
      expect(paidHow(order(status: OrderStatus.delivered, paid: PaymentStatus.paid, paidPaise: 24800)), 'Paid in cash');
    });
  });

  group('canPayNow', () {
    test('an online order that was never paid, at any stage', () {
      expect(canPayNow(order(method: PaymentMethod.online)), isTrue);
      expect(canPayNow(order(method: PaymentMethod.online, status: OrderStatus.processing)), isTrue);
    });

    test('a cash order only once the clothes are with us (before that the money is for the door)', () {
      expect(canPayNow(order()), isFalse);
      expect(canPayNow(order(status: OrderStatus.pickupAssigned)), isFalse);
      expect(canPayNow(order(status: OrderStatus.pickedUp)), isTrue);
      expect(canPayNow(order(status: OrderStatus.outForDelivery)), isTrue);
    });

    test('never when nothing is due, or the order was cancelled', () {
      expect(canPayNow(order(status: OrderStatus.processing, paid: PaymentStatus.paid, paidPaise: 24800)), isFalse);
      expect(canPayNow(order(method: PaymentMethod.online, status: OrderStatus.cancelled)), isFalse);
    });
  });

  group('delivery estimate presentation', () {
    final processing = testOrder(status: OrderStatus.processing, deliveryDate: '2026-10-06');
    test('changes at the end of the India delivery window', () {
      expect(deliveryEstimateMissed(processing, now: DateTime.utc(2026, 10, 6, 14, 29, 59)), isFalse);
      expect(deliveryEstimateMissed(processing, now: DateTime.utc(2026, 10, 6, 14, 30)), isTrue);
    });
    test('does not label terminal or pre-pickup orders as delivery overdue', () {
      for(final status in [OrderStatus.pending, OrderStatus.pickupAssigned, OrderStatus.delivered, OrderStatus.cancelled]) {
        expect(deliveryEstimateMissed(testOrder(status: status, deliveryDate: '2026-10-06'), now: DateTime.utc(2026, 10, 7)), isFalse);
      }
    });
  });

  group('settledNote', () {
    test('what happened to the money on a finished order', () {
      expect(settledNote(order(status: OrderStatus.cancelled)), 'Nothing charged');
      expect(settledNote(order(status: OrderStatus.cancelled, paid: PaymentStatus.refunded, paidPaise: 24800, refunded: 24800)), '₹248 refunded');
      expect(settledNote(order(status: OrderStatus.cancelled, paid: PaymentStatus.paid, paidPaise: 24800)), 'Refund pending');
      expect(settledNote(order(status: OrderStatus.delivered, paid: PaymentStatus.paid, paidPaise: 24800)), 'Paid in cash');
      expect(settledNote(order(status: OrderStatus.delivered, method: PaymentMethod.online, paid: PaymentStatus.paid, paidPaise: 24800)), 'Paid online');
    });
  });

  test('summarises items and counts pieces', () {
    final o = testOrder(pieces: 17);
    expect(itemsSummary(o), 'Shirt / T-shirt ×17');
    expect(piecesLabel(o), '17 items');
    expect(piecesLabel(testOrder(pieces: 1)), '1 item');
  });
}
