import 'package:flutter/material.dart';

import '../theme.dart';

enum IdButtonVariant { primary, tonal, outline, text, danger }

/// The design system's Button. One `primary` per screen; `danger` only behind a confirmation.
///
/// While [loading], the label becomes a spinner, the width is kept and taps are ignored.
/// A null [onPressed] renders the disabled state.
class IdButton extends StatelessWidget {
  const IdButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = IdButtonVariant.primary,
    this.icon,
    this.iconAtEnd = false,
    this.loading = false,
    this.expand = false,
  });

  const IdButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAtEnd = false,
    this.loading = false,
    this.expand = false,
  }) : variant = IdButtonVariant.tonal;
  const IdButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAtEnd = false,
    this.loading = false,
    this.expand = false,
  }) : variant = IdButtonVariant.outline;
  const IdButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAtEnd = false,
    this.loading = false,
    this.expand = false,
  }) : variant = IdButtonVariant.text;
  const IdButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAtEnd = false,
    this.loading = false,
    this.expand = false,
  }) : variant = IdButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final IdButtonVariant variant;
  final IconData? icon;

  /// Puts the icon after the label (a chevron on a forward action).
  final bool iconAtEnd;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final onTap = loading ? null : onPressed;

    final content = loading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: null),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null && !iconAtEnd) ...[
                Icon(icon, size: IdSize.iconMd),
                const SizedBox(width: IdSpace.s2),
              ],
              // Wraps rather than truncating when text is large: a cut-off button label is a button nobody can read.
              Flexible(
                child: Text(label, textAlign: TextAlign.center, softWrap: true),
              ),
              if (icon != null && iconAtEnd) ...[
                const SizedBox(width: IdSpace.s2),
                Icon(icon, size: IdSize.iconMd),
              ],
            ],
          );

    final Widget button = switch (variant) {
      IdButtonVariant.primary => FilledButton(
        style: loading ? FilledButton.styleFrom(disabledBackgroundColor: c.primary, disabledForegroundColor: c.onPrimary) : null,
        onPressed: onTap,
        child: _Spinnered(loading, c.onPrimary, content),
      ),
      IdButtonVariant.tonal => FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: c.primarySoft,
          foregroundColor: c.onPrimarySoft,
          disabledBackgroundColor: c.primarySoft.withValues(alpha: 0.38),
          disabledForegroundColor: c.onPrimarySoft.withValues(alpha: 0.38),
        ),
        child: _Spinnered(loading, c.onPrimarySoft, content),
      ),
      IdButtonVariant.outline => OutlinedButton(
        onPressed: onTap,
        child: _Spinnered(loading, c.text, content),
      ),
      IdButtonVariant.text => TextButton(
        onPressed: onTap,
        child: _Spinnered(loading, c.primary, content),
      ),
      IdButtonVariant.danger => FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: c.dangerSoft,
          foregroundColor: c.danger,
          disabledBackgroundColor: c.dangerSoft.withValues(alpha: 0.38),
        ),
        child: _Spinnered(loading, c.danger, content),
      ),
    };

    final semantic = Semantics(
      button: true,
      enabled: onPressed != null && !loading,
      label: loading ? '$label, loading' : null,
      excludeSemantics: loading,
      child: KeyedSubtree(key: ValueKey((variant, label)), child: button),
    );
    return expand
        ? SizedBox(width: double.infinity, child: semantic)
        : semantic;
  }
}

/// Gives the loading spinner the button's foreground colour.
class _Spinnered extends StatelessWidget {
  const _Spinnered(this.loading, this.color, this.child);
  final bool loading;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => loading
      ? ProgressIndicatorTheme(
          data: ProgressIndicatorThemeData(color: color),
          child: child,
        )
      : child;
}
