import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/links.dart';
import '../support/support.dart';

/// Goes where a notification, inbox row or website link points: a web page opens in the browser, a tab switches tabs,
/// any other screen opens on top so Back returns to where the customer was.
Future<void> openTarget(BuildContext context, WidgetRef ref, String target) async {
  if (target.startsWith('https://') || target.startsWith('http://')) {
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    try {
      await ref.read(supportLauncherProvider)(uri);
    } catch (_) {
      // No browser: nothing sensible to show instead.
    }
    return;
  }
  if (!context.mounted) return;
  if (isTabRoute(target)) {
    context.go(target);
  } else {
    await context.push<Object?>(target);
  }
}
