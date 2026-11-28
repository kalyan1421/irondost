import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../data/api_client.dart';
import '../analytics/analytics.dart';
import '../basket/basket.dart';
import '../issues/issues.dart';
import 'orders_list.dart';

/// Asks the store for its rating sheet. The store decides whether it actually shows.
abstract class StoreReview {
  Future<bool> isAvailable();
  Future<void> request();
}

class InAppStoreReview implements StoreReview {
  const InAppStoreReview();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> request() => InAppReview.instance.requestReview();
}

final storeReviewProvider = Provider<StoreReview>((_) => const InAppStoreReview());

const _seenDeliveredKey = 'milestones.delivered.v1';
const _reviewAskedKey = 'review.asked.v1';

/// Delivered orders, as the past-orders list shows them, newest first.
List<OrderDto> deliveredOrders(OrderList list) => [
      for (final o in list.items)
        if (o.status == OrderStatus.delivered) o,
    ];

/// Whether an order still has a report the team has not closed.
bool hasOpenIssue(Iterable<IssueDto> issues) =>
    issues.any((i) => i.status == IssueStatus.open || i.status == IssueStatus.acknowledged);

/// What happens when a delivery is first seen on this phone: `order_delivered` is logged, and after the customer's
/// second delivered order (with no open report about it) the store's rating sheet is asked for, once ever.
///
/// Orders already delivered when the app first looks are only remembered, so updating the app logs nothing old.
/// Watched from the tabs.
final orderMilestonesProvider = Provider<void>((ref) {
  ref.listen(ordersListProvider(Scope.past), (_, next) {
    final list = next.value;
    if (list != null) unawaited(ref.read(orderMilestonesServiceProvider).seen(list));
  }, fireImmediately: true);
});

final orderMilestonesServiceProvider = Provider<OrderMilestones>(OrderMilestones.new);

class OrderMilestones {
  OrderMilestones(this._ref);
  final Ref _ref;
  bool _asking = false;

  Future<void> seen(OrderList list) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final delivered = deliveredOrders(list);
    final known = prefs.getStringList(_seenDeliveredKey);
    final ids = delivered.map((o) => o.id).toList();
    if (known == null) {
      await prefs.setStringList(_seenDeliveredKey, ids);
      return;
    }
    final fresh = delivered.where((o) => !known.contains(o.id)).toList();
    if (fresh.isEmpty) return;
    await prefs.setStringList(_seenDeliveredKey, {...known, ...ids}.toList());
    final analytics = _ref.read(analyticsProvider);
    for (final o in fresh) {
      analytics.log(Funnel.orderDelivered, {'order_number': o.orderNumber, 'value': o.totalPaise / 100, 'currency': 'INR'});
    }
    if (delivered.length >= 2) await maybeAskForReview(fresh.first);
  }

  /// The rating sheet, at most once per install, and never while [order] has an open report.
  Future<void> maybeAskForReview(OrderDto order) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    if (_asking || (prefs.getBool(_reviewAskedKey) ?? false)) return;
    _asking = true;
    try {
      final issues = await _ref.read(issueRepositoryProvider).list(orderId: order.id);
      if (hasOpenIssue(issues.items)) return;
      final review = _ref.read(storeReviewProvider);
      if (!await review.isAvailable()) return;
      await prefs.setBool(_reviewAskedKey, true);
      await review.request();
    } catch (e) {
      debugPrint('review: not asked ($e)');
    } finally {
      _asking = false;
    }
  }
}
