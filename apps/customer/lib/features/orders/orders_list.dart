import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';
import '../auth/session.dart';
import 'order_repository.dart';

/// The orders loaded so far for one tab, and how many exist.
class OrderList {
  const OrderList({required this.items, required this.total, this.loadingMore = false, this.moreFailed = false});

  final List<OrderDto> items;
  final int total;

  /// The next page is on its way.
  final bool loadingMore;

  /// The next page could not be loaded; the list so far is intact.
  final bool moreFailed;

  bool get hasMore => items.length < total;

  OrderList copyWith({List<OrderDto>? items, int? total, bool? loadingMore, bool? moreFailed}) => OrderList(
        items: items ?? this.items,
        total: total ?? this.total,
        loadingMore: loadingMore ?? this.loadingMore,
        moreFailed: moreFailed ?? this.moreFailed,
      );
}

/// The signed-in customer's orders for [Scope.active] or [Scope.past], a page at a time.
/// Invalidate it to reload from the first page (after an order is placed, paid or cancelled).
final ordersListProvider = AsyncNotifierProvider.family<OrdersListController, OrderList, Scope>(OrdersListController.new);

class OrdersListController extends AsyncNotifier<OrderList> {
  OrdersListController(this.scope);
  final Scope scope;

  static const pageSize = 20;

  @override
  Future<OrderList> build() async {
    // Another customer signing in on this phone must never see these.
    final session = await ref.watch(sessionProvider.future);
    if (session is! SignedIn) return const OrderList(items: [], total: 0);
    final page = await ref.read(orderRepositoryProvider).list(scope, pageSize: pageSize);
    return OrderList(items: page.items, total: page.total.toInt());
  }

  /// Appends the next page. Does nothing while one is loading or when everything is here.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(loadingMore: true, moreFailed: false));
    try {
      final next = current.items.length ~/ pageSize + 1;
      final page = await ref.read(orderRepositoryProvider).list(scope, page: next, pageSize: pageSize);
      final seen = {for (final o in current.items) o.id};
      state = AsyncData(
        OrderList(items: [...current.items, for (final o in page.items) if (!seen.contains(o.id)) o], total: page.total.toInt()),
      );
    } on ApiFailure {
      state = AsyncData(current.copyWith(loadingMore: false, moreFailed: true));
    }
  }
}

/// Reloads both tabs: something changed an order (placed, paid, cancelled, moved on).
void refreshOrders(WidgetRef ref) => ref
  ..invalidate(ordersListProvider(Scope.active))
  ..invalidate(ordersListProvider(Scope.past));
