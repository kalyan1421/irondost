import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';
import '../auth/session.dart';

/// The customer's inbox on the server: order updates, payments, refunds, offers.
abstract class NotificationRepository {
  Future<NotificationPageDto> list({int page = 1, int pageSize = 20});
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._api);
  final IronDostApi _api;

  @override
  Future<NotificationPageDto> list({int page = 1, int pageSize = 20}) => _guard(() => _api.me.notificationsControllerList(page: page, pageSize: pageSize));

  @override
  Future<void> markRead(String id) => _guard(() => _api.me.notificationsControllerRead(id: id));

  @override
  Future<void> markAllRead() => _guard(_api.me.notificationsControllerReadAll);

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiFailure.from(e);
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => ApiNotificationRepository(ref.watch(apiProvider)));

/// What the notification points at, if anything: the order it is about.
String? notificationOrderId(NotificationDto n) {
  final data = n.data;
  return data is Map && data['orderId'] is String ? data['orderId'] as String : null;
}

class NotificationList {
  const NotificationList({required this.items, required this.total, required this.unread, this.loadingMore = false, this.moreFailed = false});

  final List<NotificationDto> items;
  final int total;
  final int unread;
  final bool loadingMore;
  final bool moreFailed;

  bool get hasMore => items.length < total;

  NotificationList copyWith({List<NotificationDto>? items, int? total, int? unread, bool? loadingMore, bool? moreFailed}) => NotificationList(
        items: items ?? this.items,
        total: total ?? this.total,
        unread: unread ?? this.unread,
        loadingMore: loadingMore ?? this.loadingMore,
        moreFailed: moreFailed ?? this.moreFailed,
      );
}

final notificationsProvider = AsyncNotifierProvider<NotificationsController, NotificationList>(NotificationsController.new);

class NotificationsController extends AsyncNotifier<NotificationList> {
  static const pageSize = 20;

  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  @override
  Future<NotificationList> build() async {
    final session = await ref.watch(sessionProvider.future);
    if (session is! SignedIn) return const NotificationList(items: [], total: 0, unread: 0);
    final page = await _repo.list(pageSize: pageSize);
    return NotificationList(items: page.items, total: page.total.toInt(), unread: page.unread.toInt());
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(loadingMore: true, moreFailed: false));
    try {
      final page = await _repo.list(page: current.items.length ~/ pageSize + 1, pageSize: pageSize);
      final seen = {for (final n in current.items) n.id};
      state = AsyncData(
        NotificationList(
          items: [...current.items, for (final n in page.items) if (!seen.contains(n.id)) n],
          total: page.total.toInt(),
          unread: page.unread.toInt(),
        ),
      );
    } on ApiFailure {
      state = AsyncData(current.copyWith(loadingMore: false, moreFailed: true));
    }
  }

  /// Marks one read at once on screen, then tells the server. A failure leaves it read here; the
  /// next load shows the truth.
  Future<void> markRead(String id) async {
    final current = state.value;
    if (current == null) return;
    final target = current.items.where((n) => n.id == id).firstOrNull;
    if (target == null || target.readAt != null) return;
    state = AsyncData(
      current.copyWith(
        items: [for (final n in current.items) n.id == id ? _read(n) : n],
        unread: (current.unread - 1).clamp(0, 1 << 30),
      ),
    );
    try {
      await _repo.markRead(id);
    } on ApiFailure {
      // Not worth interrupting anyone for.
    }
  }

  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null || current.unread == 0) return;
    state = AsyncData(current.copyWith(items: [for (final n in current.items) _read(n)], unread: 0));
    try {
      await _repo.markAllRead();
    } on ApiFailure {
      ref.invalidateSelf();
    }
  }

  static NotificationDto _read(NotificationDto n) => n.readAt != null
      ? n
      : NotificationDto(id: n.id, type: n.type, title: n.title, body: n.body, data: n.data, readAt: DateTime.now(), createdAt: n.createdAt);
}

/// Unread notifications, for the bell.
final unreadCountProvider = Provider<int>((ref) => ref.watch(notificationsProvider).value?.unread ?? 0);
