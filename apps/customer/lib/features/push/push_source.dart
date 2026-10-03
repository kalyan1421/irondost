import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A push notification, as far as the app needs it: what to show and where it points.
@immutable
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;

  /// The server's data fields: `type`, `orderId`, `status`, `orderNumber`.
  final Map<String, String> data;

  String? get orderId => data['orderId'];
  String get type => data['type'] ?? '';
}

enum PushPermission {
  /// Not asked yet: the system prompt can still be shown.
  notDetermined,
  granted,

  /// Refused (or switched off in Settings): only Settings can change it now.
  denied,
}

/// Where pushes come from. Firebase in the app, a script in tests.
abstract class PushSource {
  /// Arrives while the app is on screen.
  Stream<PushMessage> get foreground;

  /// The customer tapped a notification while the app was in the background.
  Stream<PushMessage> get opened;

  /// The notification that launched the app, if it was launched by tapping one.
  Future<PushMessage?> launchedBy();

  Future<PushPermission> permission();

  /// Shows the system prompt (once it can be shown at all).
  Future<PushPermission> request();
}

class FirebasePushSource implements PushSource {
  const FirebasePushSource();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  static PushMessage _from(RemoteMessage m) => PushMessage(
        title: m.notification?.title,
        body: m.notification?.body,
        data: {for (final e in m.data.entries) e.key: '${e.value}'},
      );

  static PushPermission _status(AuthorizationStatus s) => switch (s) {
        AuthorizationStatus.authorized || AuthorizationStatus.provisional => PushPermission.granted,
        AuthorizationStatus.denied || AuthorizationStatus.deniedPermanently => PushPermission.denied,
        AuthorizationStatus.notDetermined => PushPermission.notDetermined,
      };

  @override
  Stream<PushMessage> get foreground => FirebaseMessaging.onMessage.map(_from);

  @override
  Stream<PushMessage> get opened => FirebaseMessaging.onMessageOpenedApp.map(_from);

  @override
  Future<PushMessage?> launchedBy() async {
    final m = await _fcm.getInitialMessage();
    return m == null ? null : _from(m);
  }

  @override
  Future<PushPermission> permission() async => _status((await _fcm.getNotificationSettings()).authorizationStatus);

  @override
  Future<PushPermission> request() async => _status((await _fcm.requestPermission()).authorizationStatus);
}

final pushSourceProvider = Provider<PushSource>((ref) => const FirebasePushSource());
