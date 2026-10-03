import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../data/api_client.dart';
import '../basket/basket.dart';
import '../notifications/notifications.dart';
import '../orders/order_repository.dart';
import '../orders/orders_list.dart';
import 'device_registrar.dart';
import 'push_source.dart';

/// Where tapping a notification should go: its order, the offers, else the inbox.
String routeForPush(PushMessage m) {
  final orderId = m.orderId;
  if (orderId != null && orderId.isNotEmpty) return Routes.order(orderId);
  if (m.type.contains('offer') || m.type.contains('promo')) return Routes.offers;
  return Routes.notifications;
}

/// A push that arrived while the app was open, to be shown as a banner. Null when none is showing.
final inAppPushProvider = NotifierProvider<InAppPush, PushMessage?>(InAppPush.new);

class InAppPush extends Notifier<PushMessage?> {
  @override
  PushMessage? build() => null;

  void show(PushMessage m) => state = m;

  /// The banner was handed to the screen; nothing is waiting.
  void clear() => state = null;
}

/// What a tapped notification asks the app to open. The shell turns it into navigation.
final pushTapProvider = NotifierProvider<PushTap, String?>(PushTap.new);

class PushTap extends Notifier<String?> {
  @override
  String? build() => null;

  void open(String route) => state = route;
  void done() => state = null;
}

/// Listens for pushes while the signed-in tabs are on screen: an arriving one refreshes the inbox and
/// the order it is about and is offered as a banner; a tapped one opens where it points. Watch it from the shell.
final pushHandlerProvider = Provider<void>((ref) {
  final source = ref.watch(pushSourceProvider);

  final subs = <StreamSubscription<PushMessage>>[
    source.foreground.listen((m) {
      ref.invalidate(notificationsProvider);
      final id = m.orderId;
      if (id != null) {
        ref.invalidate(orderProvider(id));
        ref.invalidate(ordersListProvider(Scope.active));
      }
      ref.read(inAppPushProvider.notifier).show(m);
    }),
    source.opened.listen((m) => ref.read(pushTapProvider.notifier).open(routeForPush(m))),
  ];
  ref.onDispose(() {
    for (final s in subs) {
      s.cancel();
    }
  });

  // The app was started by tapping a notification.
  unawaited(
    source.launchedBy().then((m) {
      if (m != null) ref.read(pushTapProvider.notifier).open(routeForPush(m));
    }, onError: (_) {}),
  );
});

const _askedKey = 'push.asked.v1';

final pushOfferProvider = Provider<PushOffer>(PushOffer.new);

/// Offering notifications at the right moment (after the first booking), at most once.
class PushOffer {
  PushOffer(this._ref);
  final Ref _ref;

  /// Whether it is time to offer them: the system prompt can still be shown and the customer has not
  /// already said "Not now" to ours.
  Future<bool> shouldOffer() async {
    if (_ref.read(sharedPreferencesProvider).getBool(_askedKey) ?? false) return false;
    try {
      return await _ref.read(pushSourceProvider).permission() == PushPermission.notDetermined;
    } catch (_) {
      return false; // no push on this device (simulator, no Play services)
    }
  }

  /// Never offer again.
  Future<void> markOffered() => _ref.read(sharedPreferencesProvider).setBool(_askedKey, true);

  /// "Turn on notifications": the system prompt and, if allowed, registering this phone with the API.
  Future<PushPermission> turnOn() async {
    await markOffered();
    final result = await _ref.read(pushSourceProvider).request();
    if (result == PushPermission.granted) unawaited(_ref.read(deviceRegistrarProvider).register());
    return result;
  }
}
