import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';

/// Flat content section. Kept as a shared wrapper for existing screen composition.
class IdCard extends StatelessWidget {
  const IdCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: IdSpace.s4),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(24);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: c.royal.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: _inset(padding), child: child),
        ),
      ),
    );
  }
}

/// White cards need their content off the edges: a padding with no sides (the old flat sections) gets the card inset.
EdgeInsetsGeometry _inset(EdgeInsetsGeometry padding) {
  if (padding == EdgeInsets.zero) return padding;
  final p = padding.resolve(TextDirection.ltr);
  return p.left == 0 && p.right == 0
      ? p.copyWith(left: IdSpace.s4, right: IdSpace.s4)
      : padding;
}

/// A grouped list of [IdListRow]s with dividers, as on the Account screen.
class IdListGroup extends StatelessWidget {
  const IdListGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IdCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const Divider(),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// A settings-style row: icon, label, optional value and a chevron when tappable.
class IdListRow extends StatelessWidget {
  const IdListRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final fg = destructive ? c.danger : c.text;
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: IdSpace.s4,
              vertical: IdSpace.s3,
            ),
            child: Builder(
              builder: (context) {
                final labelText = Text(
                  label,
                  style: t.bodyLg.copyWith(
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                );
                final valueText = value == null
                    ? null
                    : Text(
                        value!,
                        style: t.body.copyWith(color: c.textMuted),
                        textAlign: TextAlign.end,
                      );
                // With large text there is no room for the value beside the label, so it goes underneath (as in iOS Settings).
                final stacked =
                    valueText != null &&
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                return Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: destructive ? c.dangerSoft : c.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: IdSize.iconMd - 2,
                        color: destructive ? c.danger : c.primary,
                      ),
                    ),
                    const SizedBox(width: IdSpace.s3),
                    Expanded(
                      child: stacked
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [labelText, valueText],
                            )
                          : labelText,
                    ),
                    if (valueText != null && !stacked) ...[
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                        ),
                        child: valueText,
                      ),
                      const SizedBox(width: IdSpace.s2),
                    ],
                    if (onTap != null && !destructive)
                      Icon(
                        LucideIcons.chevronRight,
                        size: IdSize.iconSm,
                        color: c.textMuted,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The IronDost logo for the current theme.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 36, this.tagline = false});

  final double height;
  final bool tagline;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = tagline ? 'irondost-logo-tagline' : 'irondost-wordmark';
    return Image.asset(
      'assets/brand/$name${dark ? '-reverse' : ''}.png',
      height: height,
      semanticLabel: tagline ? 'IronDost. Wash, iron, deliver.' : 'IronDost',
    );
  }
}
