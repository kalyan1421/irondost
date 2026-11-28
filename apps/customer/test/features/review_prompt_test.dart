import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/analytics/analytics.dart';
import 'package:irondost_customer/features/issues/issues.dart';
import 'package:irondost_customer/features/orders/order_milestones.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/orders/orders_list.dart';

import '../helpers.dart';

class FakeStoreReview implements StoreReview {
  bool available = true;
  int requested = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> request() async => requested++;
}

class FakeIssues implements IssueRepository {
  final open = <String>{};
  final asked = <String?>[];

  @override
  Future<IssuePageDto> list({String? orderId, int page = 1}) async {
    asked.add(orderId);
    final items = [
      if (open.contains(orderId))
        IssueDto(
          id: 'i-$orderId',
          orderId: orderId!,
          orderNumber: 'ID$orderId',
          category: IssueCategory.quality,
          status: IssueStatus.open,
          description: 'Collar still creased',
          photoUrls: const [],
          firstResponseDueAt: null,
          acknowledgedAt: null,
          resolvedAt: null,
          resolutionNote: null,
          compensationPaise: null,
          createdAt: DateTime.utc(2026, 11, 20),
          updatedAt: DateTime.utc(2026, 11, 20),
          messages: const [],
        ),
    ];
    return IssuePageDto(items: items, page: 1, pageSize: 25, total: items.length);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();

  @override
  Future<String> upload(Uint8List bytes, String name, {CancelToken? cancelToken, void Function(int, int)? onProgress}) =>
      throw UnimplementedError();
}

void main() {
  late FakeOrderRepository orders;
  late FakeStoreReview review;
  late FakeIssues issues;
  late RecordingAnalytics analytics;

  OrderDto delivered(String id) => testOrder(id: id, number: 'ID$id', status: OrderStatus.delivered, deliveredAt: DateTime.utc(2026, 11, 20));

  Future<ProviderContainer> start(List<OrderDto> listed, {Map<String, Object> saved = const {}}) async {
    orders = FakeOrderRepository()..listed.addAll(listed);
    review = FakeStoreReview();
    issues = FakeIssues();
    analytics = RecordingAnalytics();
    final c = ProviderContainer(
      overrides: [
        ...await basketOverrides(saved: saved),
        orderRepositoryProvider.overrideWithValue(orders),
        storeReviewProvider.overrideWithValue(review),
        issueRepositoryProvider.overrideWithValue(issues),
        analyticsSinkProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(c.dispose);
    c.listen(orderMilestonesProvider, (_, _) {});
    await settle(c);
    return c;
  }

  Future<void> deliver(ProviderContainer c, OrderDto order) async {
    orders.listed.insert(0, order);
    c.invalidate(ordersListProvider(Scope.past));
    await settle(c);
  }

  test('orders already delivered when the app first looks are remembered, not logged or rated', () async {
    await start([delivered('2'), delivered('1')]);
    expect(analytics.names, isEmpty);
    expect(review.requested, 0);
  });

  test('the first delivery is logged; the store rating waits for the second', () async {
    final c = await start([]);
    await deliver(c, delivered('1'));
    expect(analytics.names, [Funnel.orderDelivered]);
    expect(review.requested, 0);

    await deliver(c, delivered('2'));
    expect(analytics.names, [Funnel.orderDelivered, Funnel.orderDelivered]);
    expect(issues.asked, ['2']);
    expect(review.requested, 1);
  });

  test('asks once ever, however many deliveries follow', () async {
    final c = await start([delivered('1')]);
    await deliver(c, delivered('2'));
    await deliver(c, delivered('3'));
    expect(review.requested, 1);
  });

  test('not while the delivered order has an open report, and it can ask after a later one', () async {
    final c = await start([delivered('1')]);
    issues.open.add('2');
    await deliver(c, delivered('2'));
    expect(review.requested, 0);

    await deliver(c, delivered('3'));
    expect(review.requested, 1);
  });

  test('the flag survives a restart', () async {
    final c = await start([delivered('1')], saved: {'review.asked.v1': true, 'milestones.delivered.v1': ['1']});
    await deliver(c, delivered('2'));
    expect(review.requested, 0);
  });

  test('where the store has no rating sheet nothing is marked, so a later delivery can still ask', () async {
    final c = await start([delivered('1')]);
    review.available = false;
    await deliver(c, delivered('2'));
    review.available = true;
    await deliver(c, delivered('3'));
    expect(review.requested, 1);
  });
}

Future<void> settle(ProviderContainer c) async {
  for (var i = 0; i < 5; i++) {
    await pumpEventQueue();
  }
}
