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
    final radius = BorderRadius.circular(IdRadius.sm);
    if (quantity == 0 && showAddWhenEmpty) {
      return Semantics(
        button: true,
        label: 'Add $name',
        excludeSemantics: true,
        child: Material(
          color: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: c.borderStrong),
          ),
          child: InkWell(
            borderRadius: radius,
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
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: c.borderStrong),
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
                constraints: const BoxConstraints(minWidth: IdSpace.s6),
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: context.text.label.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            _StepButton(
              icon: LucideIcons.plus,
              label: 'Add one $name',
              onTap: canAdd ? onAdd : null,
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
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: label,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      child: SizedBox.square(
        dimension: IdSize.touchTarget,
        child: Icon(
          icon,
          size: IdSize.iconSm,
          color: onTap == null
              ? context.colors.textMuted
              : context.colors.primary,
        ),
      ),
    ),
  );
}
