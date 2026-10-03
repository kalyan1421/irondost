import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/surfaces.dart';
import 'push_handler.dart';

/// "Know when we're at your door": the reason to allow notifications, shown once after the first
/// booking and before the system prompt, so the prompt is not the first the customer hears of it.
class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  ConsumerState<NotificationPermissionScreen> createState() => _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState extends ConsumerState<NotificationPermissionScreen> {
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
                        Semantics(header: true, child: Text("Know when we're at your door", style: t.headline, textAlign: TextAlign.center)),
                        const SizedBox(height: IdSpace.s2),
                        Text(
                          "We'll tell you when a partner is on the way, when your clothes are ready and when they're delivered. Offers only if you want them.",
                          style: t.bodyLg.copyWith(color: c.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s3, IdSpace.s4, IdSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IdButton(label: 'Turn on notifications', icon: LucideIcons.bell, loading: _asking, onPressed: _turnOn),
                    const SizedBox(height: IdSpace.s1),
                    IdButton.text(label: 'Not now', onPressed: _asking ? null : _notNow),
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

/// Two example notifications, the way they will look.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    Widget card(String when, String text, {double opacity = 1, bool raised = false}) => Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(IdRadius.lg), boxShadow: raised ? context.shadows.raised : null),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: c.surfaceSoft, borderRadius: BorderRadius.circular(IdRadius.sm)),
                  child: Image.asset('assets/brand/irondost-mark.png', fit: BoxFit.contain),
                ),
                const SizedBox(width: IdSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(TextSpan(text: 'IronDost ', children: [TextSpan(text: '· $when', style: t.caption.copyWith(color: c.textMuted))]), style: t.labelSm),
                      Text(text, style: t.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: IdSpace.s4),
          decoration: BoxDecoration(color: c.surfaceSoft, borderRadius: BorderRadius.circular(IdRadius.xl)),
          child: Column(
            children: [
              card('now', 'Ravi is on the way to collect your clothes.', raised: true),
              const SizedBox(height: 10),
              card('Sat', 'Order ID001042 is on its way.', opacity: 0.7),
            ],
          ),
        ),
        const Positioned(right: 18, top: -10, child: Bubble(28)),
        const Positioned(right: 52, top: -18, child: Bubble(14)),
      ],
    );
  }
}
