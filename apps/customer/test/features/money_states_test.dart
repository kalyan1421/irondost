import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/orders/order_bill_screen.dart';
import 'package:irondost_customer/features/payment/payment_receipt_screen.dart';
import '../helpers.dart';

void main() {
  testWidgets('a failed receipt fetch never claims payment success and can recover', (tester) async {
    final repo = FakeOrderRepository()..getFailure = const ApiFailure(ApiFailureKind.offline, code: 'OFFLINE', message: 'offline');
    final confirmedAt = DateTime.utc(2026, 10, 3, 12);
    await tester.pumpWidget(themed(const PaymentReceiptScreen(orderId: 'o-1'), overrides: [orderRepositoryProvider.overrideWithValue(repo)]));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't confirm this payment"), findsOneWidget);
    expect(find.textContaining('fully paid'), findsNothing);
    repo.getFailure = null;
    repo.orders['o-1'] = testOrder(paymentStatus: PaymentStatus.paid, paidPaise: 24800, payments: [
      OrderPaymentDto(id: 'p', provider: PaymentProvider.razorpay, amountPaise: 18000, reference: 'pay_receipt', capturedAt: confirmedAt),
    ]);
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    expect(find.text('₹180 paid'), findsOneWidget);
    expect(find.text('Total received: ₹248'), findsOneWidget);
    expect(find.text('pay_receipt'), findsOneWidget);
    expect(find.text('Sat 3 Oct, 5:30 PM'), findsOneWidget);
  });

  testWidgets('a direct receipt route cannot turn an unpaid order into a success', (tester) async {
    await tester.pumpWidget(themed(const PaymentReceiptScreen(orderId: 'o-1'), overrides: [orderRepositoryProvider.overrideWithValue(FakeOrderRepository())]));
    await tester.pumpAndSettle();
    expect(find.text('Check your order payment'), findsOneWidget);
    expect(find.textContaining('fully paid'), findsNothing);
  });

  testWidgets('a direct bill load failure offers retry instead of a permanent spinner', (tester) async {
    final repo = FakeOrderRepository()..getFailure = const ApiFailure(ApiFailureKind.offline, code: 'OFFLINE', message: 'offline');
    await tester.pumpWidget(themed(const OrderBillScreen(orderId: 'o-1'), overrides: [orderRepositoryProvider.overrideWithValue(repo)]));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load this bill"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    repo.getFailure = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Items and bill'), findsOneWidget);
    expect(find.text('ID001046'), findsOneWidget);
  });
}
