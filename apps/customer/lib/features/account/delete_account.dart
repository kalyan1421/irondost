import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../auth/session.dart';
import 'account_repository.dart';

/// "Delete your account?" The account is deleted on the server first; only then is this phone signed
/// out, so a failed deletion never leaves the customer signed out of an account that still exists.
Future<void> confirmDeleteAccount(BuildContext context, WidgetRef ref) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      isDismissible: true,
      builder: (_) => const _DeleteSheet(),
    );

class _DeleteSheet extends ConsumerStatefulWidget {
  const _DeleteSheet();

  @override
  ConsumerState<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends ConsumerState<_DeleteSheet> {
  bool _deleting = false;
  String? _error;

  /// Set when the API refuses because orders are in progress.
  int? _activeOrders;

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ref.read(accountRepositoryProvider).deleteAccount();
    } on ApiFailure catch (e) {
      if (!mounted) return;
      if (e.code == 'ACTIVE_ORDERS') {
        final n = e.details?['activeOrders'];
        setState(() {
          _deleting = false;
          _activeOrders = n is num ? n.toInt() : 1;
        });
      } else {
        setState(() {
          _deleting = false;
          _error = e.isConnectivity
              ? "You're offline. Your account has not been deleted. Check your connection and try again."
              : "Couldn't delete your account. It's still active. Please try again.";
        });
      }
      return;
    }
    // Gone on the server: sign this phone out. The router sends the customer to Welcome.
    await ref.read(sessionProvider.notifier).accountDeleted();
    if (navigator.mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final blocked = _activeOrders != null;
    final (bg, fg, icon) = blocked ? (c.warningSoft, c.warning, LucideIcons.package) : (c.dangerSoft, c.danger, LucideIcons.trash2);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(IdSpace.s4, 0, IdSpace.s4, IdSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, size: IdSize.iconLg, color: fg)),
            const SizedBox(height: IdSpace.s3),
            Semantics(header: true, liveRegion: true, child: Text(blocked ? 'Finish your orders first' : 'Delete your account?', style: t.headline)),
            const SizedBox(height: IdSpace.s2),
            if (blocked)
              Text(
                'You have $_activeOrders ${_activeOrders == 1 ? 'order' : 'orders'} in progress. You can delete your account once ${_activeOrders == 1 ? "it's" : "they're"} delivered or cancelled.',
                style: t.bodyLg.copyWith(color: c.textMuted),
              )
            else ...[
              Text('This removes your name, phone number and addresses. Past orders stay in our records without your details.', style: t.bodyLg.copyWith(color: c.textMuted)),
              const SizedBox(height: IdSpace.s2),
              Text("You'll be signed out on every device. This can't be undone.", style: t.body.copyWith(color: c.textMuted)),
            ],
            if (_error != null) ...[
              const SizedBox(height: IdSpace.s3),
              Semantics(liveRegion: true, child: Text(_error!, style: t.body.copyWith(color: c.danger))),
            ],
            const SizedBox(height: IdSpace.s5),
            if (blocked) ...[
              IdButton(
                label: 'View orders',
                expand: true,
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.pop(context);
                  router.go(Routes.orders);
                },
              ),
              const SizedBox(height: IdSpace.s2),
              IdButton.outline(label: 'Close', expand: true, onPressed: () => Navigator.pop(context)),
            ] else ...[
              IdButton.danger(label: 'Delete account', expand: true, loading: _deleting, onPressed: _delete),
              const SizedBox(height: IdSpace.s2),
              IdButton.outline(label: 'Keep my account', expand: true, onPressed: _deleting ? null : () => Navigator.pop(context)),
            ],
          ],
        ),
      ),
    );
  }
}
