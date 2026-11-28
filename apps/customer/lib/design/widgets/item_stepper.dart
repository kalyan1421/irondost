import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';

/// Neutral quantity control; all actions have a full 48 dp touch target.
class ItemStepper extends StatelessWidget {
  const ItemStepper({
    super.key,
    required this.name,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    this.canAdd = true,
    this.showAddWhenEmpty = true,
  });
  final String name;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool canAdd;
  final bool showAddWhenEmpty;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (quantity == 0 && showAddWhenEmpty) {
      return Semantics(
        button: true,
        label: 'Add $name',
        excludeSemantics: true,
        child: Material(
          color: c.surface,
          shape: StadiumBorder(side: BorderSide(color: c.primary, width: 1.5)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: canAdd ? onAdd : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: IdSpace.s4,
                vertical: IdSpace.s3,
              ),
              child: Text(
                'Add',
                style: context.text.label.copyWith(color: c.primary),
              ),
            ),
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      label: '$name, $quantity in basket',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.primarySoft,
          borderRadius: BorderRadius.circular(IdRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: LucideIcons.minus,
              label: 'Remove one $name',
              onTap: quantity > 0 ? onRemove : null,
            ),
            ExcludeSemantics(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: IdSpace.s5),
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: context.text.label.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            _StepButton(
              icon: LucideIcons.plus,
              label: 'Add one $name',
              onTap: canAdd ? onAdd : null,
              filled: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// The add button is a solid blue dot; remove is a white one.
  final bool filled;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    final bg = filled
        ? (enabled ? c.primary : c.primary.withValues(alpha: 0.38))
        : c.surface;
    final fg = filled ? c.onPrimary : (enabled ? c.text : c.textMuted);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: IdSize.touchTarget / 2,
        child: SizedBox.square(
          dimension: IdSize.touchTarget,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: IdSize.iconSm, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}
