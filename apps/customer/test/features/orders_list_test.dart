import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/app/provider_retry.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/auth/session.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/orders/orders_list.dart';

import '../helpers.dart';

void main() {
  late FakeOrderRepository repo;

  ProviderContainer open({bool signedIn = true}) {
    repo = FakeOrderRepository();
    final container = ProviderContainer(
      retry: noAutomaticRetry,
      overrides: [
        orderRepositoryProvider.overrideWithValue(repo),
        if (signedIn) sessionProvider.overrideWith(SignedInSession.new) else sessionProvider.overrideWith(_SignedOut.new),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  List<OrderDto> past(int n) => [for (var i = 0; i < n; i++) testOrder(id: 'p$i', number: 'ID${1000 - i}', status: OrderStatus.delivered)];

  test('loads the first page of the tab asked for, and how many there are in all', () async {
    final c = open();
    repo.listed.addAll([testOrder(id: 'a1'), testOrder(id: 'a2'), ...past(3)]);

    final active = await c.read(ordersListProvider(Scope.active).future);
    expect(active.items.map((o) => o.id), ['a1', 'a2']);
    expect(active.total, 2);
    expect(active.hasMore, isFalse);

    final finished = await c.read(ordersListProvider(Scope.past).future);
    expect(finished.items, hasLength(3));
    expect(repo.listAsked, [(Scope.active, 1), (Scope.past, 1)]);
  });

  test('loads further pages as asked, once each, until everything is here', () async {
    final c = open();
    repo.listed.addAll(past(45));
    await c.read(ordersListProvider(Scope.past).future);
    final list = c.read(ordersListProvider(Scope.past).notifier);

    expect(c.read(ordersListProvider(Scope.past)).requireValue.hasMore, isTrue);
    await Future.wait([list.loadMore(), list.loadMore()]); // two calls at once: one request
    expect(c.read(ordersListProvider(Scope.past)).requireValue.items, hasLength(40));
    expect(repo.listAsked.where((a) => a.$2 == 2), hasLength(1));

    await list.loadMore();
    expect(c.read(ordersListProvider(Scope.past)).requireValue.items, hasLength(45));
    expect(c.read(ordersListProvider(Scope.past)).requireValue.hasMore, isFalse);
    await list.loadMore(); // nothing left
    expect(repo.listAsked.where((a) => a.$2 == 4), isEmpty);
  });

  test('a page that fails keeps what is already shown and says more could not be loaded', () async {
    final c = open();
    repo.listed.addAll(past(30));
    await c.read(ordersListProvider(Scope.past).future);
    repo.listFailure = const ApiFailure(ApiFailureKind.offline);

    await c.read(ordersListProvider(Scope.past).notifier).loadMore();
    var list = c.read(ordersListProvider(Scope.past)).requireValue;
    expect(list.items, hasLength(20));
    expect(list.moreFailed, isTrue);
    expect(list.loadingMore, isFalse);

    repo.listFailure = null;
    await c.read(ordersListProvider(Scope.past).notifier).loadMore();
    list = c.read(ordersListProvider(Scope.past)).requireValue;
    expect(list.items, hasLength(30));
    expect(list.moreFailed, isFalse);
  });

  test('a first page that fails is an error until reloaded', () async {
    final c = open();
    repo.listFailure = const ApiFailure(ApiFailureKind.server);
    await c.read(ordersListProvider(Scope.active).future).then((_) {}, onError: (_) {});
    expect(c.read(ordersListProvider(Scope.active)).hasError, isTrue);
    expect(c.read(ordersListProvider(Scope.active)).error, isA<ApiFailure>());

    repo.listFailure = null;
    repo.listed.add(testOrder());
    c.invalidate(ordersListProvider(Scope.active));
    expect((await c.read(ordersListProvider(Scope.active).future)).items, hasLength(1));
  });

  test('nobody signed in sees nothing and nothing is asked', () async {
    final c = open(signedIn: false);
    repo.listed.add(testOrder());
    final list = await c.read(ordersListProvider(Scope.active).future);
    expect(list.items, isEmpty);
    expect(repo.listAsked, isEmpty);
  });
}

class _SignedOut extends SessionController {
  @override
  Future<Session> build() async => const SignedOut();
}
