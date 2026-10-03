import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../app/env.dart';
import '../../data/api_client.dart';
import '../auth/auth_repository.dart';
import '../auth/session.dart';
import '../notifications/notifications.dart';
import '../orders/order_repository.dart';
import '../orders/orders_list.dart';

/// What the server pushes when an order changes (`order.updated` on `/v1/realtime`). It carries the
/// new status at most; anything more is fetched over REST.
class OrderUpdate {
  const OrderUpdate({required this.orderId, this.orderNumber, this.status, this.reason});

  final String orderId;
  final String? orderNumber;
  final OrderStatus? status;

  /// created, status_changed, items_changed, payment_changed, details_changed, refund_changed.
  final String? reason;

  factory OrderUpdate.fromJson(Map<Object?, Object?> json) => OrderUpdate(
        orderId: json['orderId']! as String,
        orderNumber: json['orderNumber'] as String?,
        status: json['status'] is String ? OrderStatus.fromJson(json['status']! as String) : null,
        reason: json['reason'] as String?,
      );

  /// The order is over: it moves from the Active tab to Past.
  bool get finishes => status == OrderStatus.delivered || status == OrderStatus.cancelled;
}

/// A live connection to the API. Listening connects; cancelling disconnects.
abstract class RealtimeSource {
  Stream<OrderUpdate> updates();
}

/// Socket.IO, authenticated with the same bearer token as the REST calls. The token is asked for
/// again on every reconnect, so an expired one never keeps the socket out.
class SocketRealtimeSource implements RealtimeSource {
  SocketRealtimeSource({required this.baseUrl, required this.token});

  final String baseUrl;
  final Future<String?> Function() token;

  @override
  Stream<OrderUpdate> updates() {
    io.Socket? socket;
    late final StreamController<OrderUpdate> controller;
    controller = StreamController<OrderUpdate>(
      onListen: () {
        socket = io.io(
          baseUrl,
          io.OptionBuilder()
              .setTransports(['websocket'])
              .setPath('/v1/realtime')
              .setAuthFn((callback) => token().then((t) => callback({'token': t ?? ''})))
              .setReconnectionDelay(1000)
              .setReconnectionDelayMax(15000)
              .disableAutoConnect()
              .build(),
        )
          ..on('order.updated', (data) {
            if (data is Map && data['orderId'] is String) controller.add(OrderUpdate.fromJson(data));
          })
          ..connect();
      },
      onCancel: () {
        socket?.dispose();
        socket = null;
      },
    );
    return controller.stream;
  }
}

final realtimeSourceProvider = Provider<RealtimeSource>(
  (ref) => SocketRealtimeSource(baseUrl: AppEnv.apiBaseUrl, token: () => ref.read(authRepositoryProvider).token()),
);

/// Whether the app is on screen. The socket is held only then: in the background push does the job.
final appForegroundProvider = NotifierProvider<AppForeground, bool>(AppForeground.new);

class AppForeground extends Notifier<bool> {
  @override
  bool build() {
    final listener = AppLifecycleListener(onStateChange: (s) => state = s == AppLifecycleState.resumed);
    ref.onDispose(listener.dispose);
    return WidgetsBinding.instance.lifecycleState == null || WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }
}

/// Keeps orders fresh while the app is open: an `order.updated` refreshes that order and the lists,
/// and coming back to the app catches up on anything missed. Watch it from the signed-in shell.
final realtimeSyncProvider = Provider<void>((ref) {
  final signedIn = ref.watch(sessionProvider).value is SignedIn;
  final foreground = ref.watch(appForegroundProvider);
  if (!signedIn || !foreground) return;

  Timer? inboxTimer;
  final sub = ref.read(realtimeSourceProvider).updates().listen(
    (u) {
      ref.invalidate(orderProvider(u.orderId));
      ref.invalidate(ordersListProvider(Scope.active));
      if (u.finishes) ref.invalidate(ordersListProvider(Scope.past));
      // The inbox entry is written just after the update goes out: look again a moment later.
      inboxTimer?.cancel();
      inboxTimer = Timer(const Duration(seconds: 1), () => ref.invalidate(notificationsProvider));
    },
    onError: (_) {}, // a dropped connection is retried by the socket itself
  );
  ref.onDispose(() {
    inboxTimer?.cancel();
    sub.cancel();
  });
});
