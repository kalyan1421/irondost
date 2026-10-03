import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';

final deviceRegistrarProvider = Provider<DeviceRegistrar>((ref) {
  final registrar = DeviceRegistrar(ref.watch(apiProvider));
  ref.onDispose(registrar.dispose);
  return registrar;
});

/// Tells the API where to send this customer's push notifications.
///
/// Registers only when notifications are already allowed; asking for permission is a
/// separate screen (shown after the first booking), so sign-in never triggers a system prompt.
class DeviceRegistrar {
  DeviceRegistrar(this._api);

  final IronDostApi _api;
  StreamSubscription<String>? _refresh;
  String? _token;

  DevicePlatform get _platform => Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android;

  Future<void> register() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }
      final token = await messaging.getToken();
      if (token == null) return;
      await _send(token);
      _refresh ??= messaging.onTokenRefresh.listen(_send);
    } catch (e) {
      // No APNs on the simulator, no Play services on some emulators: push is optional.
      debugPrint('Push registration skipped: $e');
    }
  }

  Future<void> _send(String token) async {
    _token = token;
    await _api.me.usersControllerRegisterDevice(
      body: RegisterDeviceDto(fcmToken: token, platform: _platform, app: ClientApp.customer),
    );
  }

  /// Stops pushes to this phone. Call before signing out, while the token is still valid.
  Future<void> unregister() async {
    await _refresh?.cancel();
    _refresh = null;
    final token = _token;
    _token = null;
    if (token == null) return;
    try {
      await _api.me.usersControllerRemoveDevice(body: RemoveDeviceDto(fcmToken: token));
    } catch (e) {
      debugPrint('Push unregistration failed: $e');
    }
  }

  void dispose() => _refresh?.cancel();
}
