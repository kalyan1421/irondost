import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/orders/care_note_view.dart';
import 'package:irondost_customer/features/orders/order_bill_screen.dart';
import 'package:irondost_customer/features/orders/order_detail_screen.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';

import '../helpers.dart';

void main() {
  const note = 'Red silk saree: stain on the pallu. Colours may run.';
  const photos = [
    'https://files.test/care/u1/a.webp',
    'https://files.test/care/u1/b.webp',
  ];

  Future<void> pumpDetail(WidgetTester tester, OrderDto order) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 1400 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = FakeOrderRepository()..orders[order.id] = order;
    await tester.pumpWidget(
      themed(
        OrderDetailScreen(orderId: order.id, initial: order),
        overrides: [
          orderRepositoryProvider.overrideWithValue(repo),
          ...await basketOverrides(),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpBill(WidgetTester tester, OrderDto order) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 1400 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = FakeOrderRepository()..orders[order.id] = order;
    await tester.pumpWidget(
      themed(
        OrderBillScreen(orderId: order.id, initial: order),
        overrides: [orderRepositoryProvider.overrideWithValue(repo)],
      ),
    );
    await tester.pumpAndSettle();
  }

  test('an order has a care note when it has text or photos', () {
    expect(hasCareNote(testOrder()), isFalse);
    expect(hasCareNote(testOrder(careNote: '   ')), isFalse);
    expect(hasCareNote(testOrder(careNote: note)), isTrue);
    expect(hasCareNote(testOrder(carePhotoUrls: photos)), isTrue);
  });

  group('order detail', () {
    testWidgets('shows "Your care note" with the text and the photos', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        testOrder(careNote: note, carePhotoUrls: photos),
      );
      await tester.scrollUntilVisible(
        find.text('Your care note'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Your care note'), findsOneWidget);
      expect(find.text(note), findsOneWidget);
      expect(
        find.bySemanticsLabel('Photo 1 of 2, tap to enlarge'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Photo 2 of 2, tap to enlarge'),
        findsOneWidget,
      );
      expect(find.byType(Image), findsAtLeastNWidgets(2));
    });

    testWidgets('shows a note without photos, and photos without a note', (
      tester,
    ) async {
      await pumpDetail(tester, testOrder(careNote: note));
      await tester.scrollUntilVisible(
        find.text('Your care note'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(note), findsOneWidget);

      await pumpDetail(tester, testOrder(carePhotoUrls: photos));
      await tester.scrollUntilVisible(
        find.text('Your care note'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Your care note'), findsOneWidget);
      expect(find.text(note), findsNothing);
    });

    testWidgets('is not there when the customer left no note', (tester) async {
      await pumpDetail(tester, testOrder());
      expect(find.text('Your care note'), findsNothing);
    });

    testWidgets('stays on an order that is picked up or delivered', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        testOrder(
          status: OrderStatus.delivered,
          deliveredAt: DateTime.utc(2026, 10, 3, 14),
          careNote: note,
          paymentStatus: PaymentStatus.paid,
          paidPaise: 24800,
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Your care note'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(note), findsOneWidget);
    });

    testWidgets('a photo opens larger and closes again', (tester) async {
      await pumpDetail(
        tester,
        testOrder(careNote: note, carePhotoUrls: photos),
      );
      await tester.scrollUntilVisible(
        find.text('Your care note'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find
            .descendant(
              of: find.byType(OrderCareNote),
              matching: find.byType(Image),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.tap(find.byTooltip('Close photo'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('a photo that cannot load shows a placeholder, not an error', (
      tester,
    ) async {
      await pumpDetail(tester, testOrder(carePhotoUrls: photos));
      await tester.scrollUntilVisible(
        find.text('Your care note'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('the bill', () {
    testWidgets('shows "Your care note" under the bill', (tester) async {
      await pumpBill(tester, testOrder(careNote: note, carePhotoUrls: photos));
      await tester.scrollUntilVisible(
        find.text('Your care note'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(note), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Total')).dy,
        lessThan(tester.getTopLeft(find.text('Your care note')).dy),
      );
    });

    testWidgets('has nothing about care when there was no note', (
      tester,
    ) async {
      await pumpBill(tester, testOrder());
      expect(find.text('Your care note'), findsNothing);
    });
  });
}
