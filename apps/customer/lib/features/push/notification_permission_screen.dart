import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import 'push_handler.dart';

/// "Know when we're at your door": the reason to allow notifications, shown once after the first
/// booking and before the system prompt, so the prompt is not the first the customer hears of it.
class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  ConsumerState<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends ConsumerState<NotificationPermissionScreen> {
  bool _asking = false;

  Future<void> _turnOn() async {
    setState(() => _asking = true);
    await ref.read(pushOfferProvider).turnOn();
    if (mounted) context.pop();
  }

  Future<void> _notNow() async {
    await ref.read(pushOfferProvider).markOffered();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_asking) _notNow();
      },
      child: Scaffold(
        backgroundColor: c.surface,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(IdSpace.s6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ExcludeSemantics(child: _Preview()),
                        const SizedBox(height: 28),
                        Semantics(
                          header: true,
                          child: Text(
                            "Know when we're at your door",
                            style: t.headline,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: IdSpace.s2),
                        Text(
                          'Get pickup, delivery and order updates. Notifications may also include available offers. You can turn them off in your device settings.',
                          style: t.bodyLg.copyWith(color: c.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  IdSpace.s5,
                  IdSpace.s3,
                  IdSpace.s5,
                  IdSpace.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IdButton(
                      label: 'Turn on notifications',
                      icon: LucideIcons.bell,
                      loading: _asking,
                      onPressed: _turnOn,
                    ),
                    const SizedBox(height: IdSpace.s1),
                    IdButton.text(
                      label: 'Not now',
                      onPressed: _asking ? null : _notNow,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One example transactional notification.
class _Preview extends StatelessWidget {
  const _Preview();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(IdSpace.s4),
    decoration: BoxDecoration(
      color: context.colors.surfaceSoft,
      borderRadius: BorderRadius.circular(IdRadius.lg),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          LucideIcons.bell,
          size: IdSize.iconLg,
          color: context.colors.textMuted,
        ),
        const SizedBox(width: IdSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('IronDost · now', style: context.text.labelSm),
              const SizedBox(height: IdSpace.s1),
              Text(
                'Your partner is on the way to collect your clothes.',
                style: context.text.body,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
