import 'package:flutter/material.dart';

import '../theme.dart';
import 'id_button.dart';

enum StateTone { neutral, primary, success, warning, danger }

/// A full-screen state from the design system: offline, server down, force update,
/// account paused, success. A compact status mark, title and explanation with
/// actions pinned to the bottom.
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
    final actions = [
      primary,
      secondary,
      tertiary,
    ].whereType<IdButton>().toList();

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
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: bg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 32, color: fg),
                      ),
                      const SizedBox(height: IdSpace.s6),
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: t.headline,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: IdSpace.s4),
                      Text(
                        body,
                        style: t.bodyLg.copyWith(color: c.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      if (caption != null) ...[
                        const SizedBox(height: IdSpace.s4),
                        Text(
                          caption!,
                          style: t.caption.copyWith(color: c.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (actions.isNotEmpty)
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

/// A recoverable list state that keeps pull-to-refresh and large-text scrolling.
class ListStateView extends StatelessWidget {
  const ListStateView({
    super.key,
    this.icon,
    required this.title,
    required this.body,
    this.action,
    this.tone = StateTone.neutral,
    this.announce = false,
  });

  final IconData? icon;
  final String title;
  final String body;
  final Widget? action;
  final StateTone tone;
  final bool announce;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: IdSpace.s5,
              vertical: IdSpace.s6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  ExcludeSemantics(
                    child: Icon(
                      icon,
                      size: IdSpace.s8,
                      color: tone == StateTone.danger
                          ? context.colors.danger
                          : context.colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: IdSpace.s4),
                ],
                Semantics(
                  header: true,
                  liveRegion: announce,
                  child: Text(
                    title,
                    style: context.text.titleLg,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: IdSpace.s2),
                Text(
                  body,
                  style: context.text.body.copyWith(
                    color: context.colors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (action != null) ...[
                  const SizedBox(height: IdSpace.s5),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
