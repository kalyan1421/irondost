import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/reachability.dart';
import '../../design/theme.dart';
import '../push/push_handler.dart';
import '../push/push_source.dart';
import '../realtime/realtime.dart';
import 'offline_banner.dart';

/// Bottom navigation: Home, Orders, Offers, Account. Each tab keeps its own back stack;
/// tapping the current tab returns it to its first screen.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live order updates for as long as the tabs are on screen.
    ref.watch(realtimeSyncProvider);
    // Pushes while the tabs are on screen: a banner for one arriving, navigation for one tapped.
    ref
      ..watch(pushHandlerProvider)
      ..listen(inAppPushProvider, (_, message) {
        if (message != null) _showBanner(context, ref, message);
      })
      ..listen(pushTapProvider, (_, route) {
        if (route == null) return;
        ref.read(pushTapProvider.notifier).done();
        context.push(route);
      })
      // Back online: reload what the tabs show, so the banner going away leaves current data behind it.
      ..listen(reachabilityProvider, (was, now) {
        if (now && was == false) refreshAfterReconnect(ref);
      });
    final c = context.colors;
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: shell),
          const OfflineBanner(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: const [
            NavigationDestination(icon: Icon(LucideIcons.house), label: 'Home'),
            NavigationDestination(icon: Icon(LucideIcons.package), label: 'Orders'),
            NavigationDestination(icon: Icon(LucideIcons.badgePercent), label: 'Offers'),
            NavigationDestination(icon: Icon(LucideIcons.user), label: 'Account'),
          ],
        ),
      ),
    );
  }
}

/// A push that arrives while the app is open: shown as a banner with a way to open it.
void _showBanner(BuildContext context, WidgetRef ref, PushMessage message) {
  final text = context.text;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.title != null) Text(message.title!, style: text.label.copyWith(color: context.colors.textInverse, fontWeight: FontWeight.w700)),
            if (message.body != null) Text(message.body!, style: text.body.copyWith(color: context.colors.textInverse)),
          ],
        ),
        action: SnackBarAction(label: 'View', onPressed: () => context.push(routeForPush(message))),
      ),
    );
  ref.read(inAppPushProvider.notifier).clear();
}
