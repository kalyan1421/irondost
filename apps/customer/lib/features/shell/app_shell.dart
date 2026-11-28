import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/links.dart';
import '../../data/reachability.dart';
import '../basket/basket.dart';
import '../issues/issues.dart';
import '../../design/theme.dart';
import '../push/push_handler.dart';
import '../push/push_source.dart';
import '../orders/order_milestones.dart';
import '../realtime/realtime.dart';
import 'open_target.dart';
import 'offline_banner.dart';

/// Bottom navigation: Home, Orders, Basket, Profile. Each tab keeps its own back stack;
/// tapping the current tab returns it to its first screen.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live order updates for as long as the tabs are on screen.
    ref.watch(realtimeSyncProvider);
    ref.watch(issuePhotoRecoveryProvider);
    // Deliveries seen for the first time: analytics, and the one-time store rating prompt.
    ref.watch(orderMilestonesProvider);
    // Pushes while the tabs are on screen: a banner for one arriving, navigation for one tapped.
    ref
      ..watch(pushHandlerProvider)
      ..listen(inAppPushProvider, (_, message) {
        if (message != null) _showBanner(context, ref, message);
      })
      ..listen(pushTapProvider, (_, route) {
        if (route == null) return;
        ref.read(pushTapProvider.notifier).done();
        openTarget(context, ref, route);
      })
      // Back online: reload what the tabs show, so the banner going away leaves current data behind it.
      ..listen(reachabilityProvider, (was, now) {
        if (now && was == false) refreshAfterReconnect(ref);
      });
    // A website link (App Links / Universal Links), possibly from before sign-in: acted on once the tabs are up.
    final link = ref.watch(pendingLinkProvider);
    if (link != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || ref.read(pendingLinkProvider) != link) return;
        ref.read(pendingLinkProvider.notifier).done();
        openTarget(context, ref, link);
      });
    }
    final basketCount = ref.watch(basketProvider.select((b) => b.count));
    return Scaffold(
      extendBody: false,
      body: Column(
        children: [
          Expanded(child: shell),
          const OfflineBanner(),
        ],
      ),
      bottomNavigationBar: _PillNav(
        selectedIndex: shell.currentIndex,
        onSelect: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        basketCount: basketCount,
      ),
    );
  }
}

/// The floating rounded tab bar: the selected tab sits in a soft blue pill with its label.
class _PillNav extends StatelessWidget {
  const _PillNav({
    required this.selectedIndex,
    required this.onSelect,
    required this.basketCount,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final int basketCount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      (LucideIcons.house, 'Home', 0),
      (LucideIcons.package, 'Orders', 0),
      (LucideIcons.shoppingBag, 'Basket', basketCount),
      (LucideIcons.user, 'Profile', 0),
    ];
    return ColoredBox(
      color: dark ? c.bg : const Color(0xFFE6EFFC),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            IdSpace.s3,
            IdSpace.s2,
            IdSpace.s3,
            IdSpace.s3,
          ),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: IdSpace.s2),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: c.border),
              boxShadow: [
                BoxShadow(
                  color: c.royal.withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                for (final (i, item) in items.indexed)
                  Expanded(
                    flex: i == selectedIndex ? 12 : 10,
                    child: _PillTab(
                      icon: item.$1,
                      label: item.$2,
                      badge: item.$3,
                      selected: i == selectedIndex,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.icon,
    required this.label,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.onPrimarySoft : c.textMuted;
    final semanticsLabel = badge > 0
        ? '$label, $badge ${badge == 1 ? 'item' : 'items'}'
        : label;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(27),
        onTap: onTap,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(27),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                backgroundColor: c.primary,
                child: Icon(icon, size: IdSize.iconLg - 2, color: fg),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.noScaling,
                style: context.text.labelSm.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
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
            if (message.title != null)
              Text(
                message.title!,
                style: text.label.copyWith(
                  color: context.colors.textInverse,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (message.body != null)
              Text(
                message.body!,
                style: text.body.copyWith(color: context.colors.textInverse),
              ),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => openTarget(context, ref, routeForPush(message)),
        ),
      ),
    );
  ref.read(inAppPushProvider.notifier).clear();
}
