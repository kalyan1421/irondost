import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android shows a push on the channel the server names (`order_updates`), and only if the channel
/// exists. Creating them at start also lets customers tune order updates and offers separately in Settings.
Future<void> createNotificationChannels() async {
  if (!Platform.isAndroid) return;
  try {
    final android = FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'order_updates',
        'Order updates',
        description: 'Pickup, ironing, delivery and payment updates for your orders.',
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'offers',
        'Offers',
        description: 'Discounts and offers from IronDost.',
      ),
    );
  } catch (e) {
    debugPrint('Notification channels not created: $e');
  }
}
