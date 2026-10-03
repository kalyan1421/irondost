import 'package:flutter/material.dart';

import '../theme.dart';
import 'id_button.dart';

enum StateTone { neutral, primary, success, warning, danger }

/// A full-screen state from the design system: offline, server down, force update,
/// account paused, success. Icon in a tinted circle, a title, one paragraph and up to
/// two actions pinned to the bottom.
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.tone = StateTone.neutral,
    this.caption,
    this.primary,
    this.secondary,
    this.tertiary,
  });

  final IconData icon;
  final String title;
  final String body;
  final StateTone tone;
  final String? caption;
  final IdButton? primary;
  final IdButton? secondary;
  final IdButton? tertiary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final (bg, fg) = switch (tone) {
      StateTone.neutral => (c.surfaceSoft, c.textMuted),
      StateTone.primary => (c.primarySoft, c.onPrimarySoft),
      StateTone.success => (c.successSoft, c.success),
      StateTone.warning => (c.warningSoft, c.warning),
      StateTone.danger => (c.dangerSoft, c.danger),
    };
    final actions = [primary, secondary, tertiary].whereType<IdButton>().toList();

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(IdSpace.s6),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                        child: Icon(icon, size: 52, color: fg),
                      ),
                      const SizedBox(height: IdSpace.s6),
                      Semantics(header: true, child: Text(title, style: t.headline, textAlign: TextAlign.center)),
                      const SizedBox(height: IdSpace.s4),
                      Text(body, style: t.bodyLg.copyWith(color: c.textMuted), textAlign: TextAlign.center),
                      if (caption != null) ...[
                        const SizedBox(height: IdSpace.s4),
                        Text(caption!, style: t.caption.copyWith(color: c.textMuted), textAlign: TextAlign.center),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s3, IdSpace.s4, IdSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, a) in actions.indexed) ...[
                    if (i > 0) const SizedBox(height: IdSpace.s2),
                    a,
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
