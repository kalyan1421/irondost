import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/app/provider_retry.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/auth/session.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/orders/orders_list.dart';
import 'package:irondost_customer/features/realtime/realtime.dart';

import '../helpers.dart';

class _FakeRealtime implements RealtimeSource {
  int connections = 0;
  int disconnections = 0;
  StreamController<OrderUpdate>? _controller;

  @override
  Stream<OrderUpdate> updates() {
    _controller = StreamController<OrderUpdate>(onListen: () => connections++, onCancel: () => disconnections++);
    return _controller!.stream;
  }

  void push(OrderUpdate update) => _controller!.add(update);
}

class _Foreground extends AppForeground {
  _Foreground(this.initial);
  final bool initial;

  @override
  bool build() => initial;

  void set(bool value) => state = value;
}

class _SignedOut extends SessionController {
  @override
  Future<Session> build() async => const SignedOut();
}

void main() {
  late FakeOrderRepository orders;
  late _FakeRealtime realtime;

  Future<ProviderContainer> open({bool signedIn = true, bool foreground = true}) async {
    orders = FakeOrderRepository()..listed.add(testOrder());
    realtime = _FakeRealtime();
    final container = ProviderContainer(
      retry: noAutomaticRetry,
      overrides: [
        orderRepositoryProvider.overrideWithValue(orders),
        realtimeSourceProvider.overrideWithValue(realtime),
        appForegroundProvider.overrideWith(() => _Foreground(foreground)),
        if (signedIn) sessionProvider.overrideWith(SignedInSession.new) else sessionProvider.overrideWith(_SignedOut.new),
      ],
    );
    addTearDown(container.dispose);
    // What the screens hold open.
    container
      ..listen(sessionProvider, (_, _) {})
      ..listen(orderProvider('o-1'), (_, _) {})
      ..listen(ordersListProvider(Scope.active), (_, _) {})
      ..listen(ordersListProvider(Scope.past), (_, _) {});
    await container.read(sessionProvider.future);
    container.listen(realtimeSyncProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  test('parses what the server sends, and ignores fields it does not know', () {
    final update = OrderUpdate.fromJson({'orderId': 'o-1', 'orderNumber': 'ID001046', 'status': 'PICKED_UP', 'reason': 'status_changed', 'extra': 1});
    expect(update.orderId, 'o-1');
    expect(update.status, OrderStatus.pickedUp);
    expect(update.finishes, isFalse);
    expect(OrderUpdate.fromJson({'orderId': 'o-1', 'status': 'DELIVERED'}).finishes, isTrue);
    expect(OrderUpdate.fromJson({'orderId': 'o-1', 'status': 'CANCELLED'}).finishes, isTrue);
    expect(OrderUpdate.fromJson({'orderId': 'o-1', 'reason': 'payment_changed'}).status, isNull);
  });

  test('an update refetches that order and the active list', () async {
    await open();
    await settle();
    final gets = orders.getCount;
    final lists = orders.listAsked.length;

    realtime.push(const OrderUpdate(orderId: 'o-1', status: OrderStatus.processing, reason: 'status_changed'));
    await settle();

    expect(orders.getCount, gets + 1);
    expect(orders.listAsked.where((a) => a.$1 == Scope.active).length, greaterThan(lists - 1));
    expect(orders.listAsked.length, lists + 1, reason: 'only the active list, the order is not over');
  });

  test('an order that ends also refreshes the past list', () async {
    await open();
    await settle();
    final lists = orders.listAsked.length;

    realtime.push(const OrderUpdate(orderId: 'o-1', status: OrderStatus.delivered, reason: 'status_changed'));
    await settle();

    expect(orders.listAsked.length, lists + 2);
    expect(orders.listAsked.map((a) => a.$1).toSet(), {Scope.active, Scope.past});
  });

  test('nothing is held open in the background, and it reconnects on return', () async {
    final c = await open();
    expect(realtime.connections, 1);

    (c.read(appForegroundProvider.notifier) as _Foreground).set(false);
    await settle();
    expect(realtime.disconnections, 1);

    (c.read(appForegroundProvider.notifier) as _Foreground).set(true);
    await settle();
    expect(realtime.connections, 2);
  });

  test('signed out or in the background, no connection is made at all', () async {
    await open(signedIn: false);
    expect(realtime.connections, 0);
    await open(foreground: false);
    expect(realtime.connections, 0);
  });
}
