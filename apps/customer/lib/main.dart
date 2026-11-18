import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/env.dart';
import 'app/provider_retry.dart';
import 'features/basket/basket.dart';
import 'features/push/notification_channels.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kReleaseMode) {
    final problem = AppEnv.releaseProblem;
    if (problem != null) throw StateError('Release build with a development configuration: $problem. Build with --dart-define-from-file=env/prod.json.');
  }
  final (_, _, prefs) = await (
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    initializeDateFormatting('en_IN'),
    SharedPreferences.getInstance(),
  ).wait;
  await createNotificationChannels();
  runApp(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const IronDostApp(),
    ),
  );
}
