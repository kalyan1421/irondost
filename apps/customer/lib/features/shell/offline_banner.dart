import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/api_client.dart';
import '../../data/reachability.dart';
import '../../design/theme.dart';
import '../catalogue/catalogue.dart';
import '../notifications/notifications.dart';
import '../offers/promotions.dart';
import '../orders/orders_list.dart';

/// A cheap question to the API. Its success or failure reaches [Reachability], which is all Retry needs.
final connectionProbeProvider = Provider<Future<void> Function()>((ref) => () async {
      await ref.read(apiProvider).config.publicConfigControllerGet();
    });

/// Reloads what the tabs show, once the API can be reached again.
void refreshAfterReconnect(WidgetRef ref) {
  ref
    ..invalidate(catalogProvider)
    ..invalidate(promotionsProvider)
    ..invalidate(notificationsProvider)
    ..invalidate(ordersListProvider);
}

/// "You're offline. Showing what we saved." with Retry; hidden while the API is reachable.
/// It sits just above the tab bar, so it never covers a screen's own header or actions.
class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      await ref.read(connectionProbeProvider)();
    } catch (_) {
      // Still offline: the failed request has already told Reachability.
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(reachabilityProvider);
    final c = context.colors;
    final t = context.text;
    final instant = MediaQuery.disableAnimationsOf(context);

    return AnimatedSwitcher(
      duration: instant ? Duration.zero : const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SizeTransition(sizeFactor: animation, alignment: Alignment.bottomCenter, child: child)),
      child: online
          ? const SizedBox(key: ValueKey('online'), width: double.infinity)
          : Padding(
              key: const ValueKey('offline'),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Semantics(
                liveRegion: true,
                container: true,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                  decoration: BoxDecoration(color: c.surfaceInverse, borderRadius: BorderRadius.circular(IdRadius.md), boxShadow: context.shadows.raised),
                  child: Row(
                    children: [
                      Icon(LucideIcons.wifiOff, size: IdSize.iconMd, color: c.textInverse),
                      const SizedBox(width: 10),
                      Expanded(child: Text("You're offline. Some things may be out of date.", style: t.body.copyWith(color: c.textInverse))),
                      TextButton(
                        onPressed: _retrying ? null : _retry,
                        style: TextButton.styleFrom(foregroundColor: c.inverseAccent, disabledForegroundColor: c.inverseAccent),
                        child: _retrying ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
