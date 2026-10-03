import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';

/// The design system's quantity control: an outlined "ADD" pill while the item is not in the basket,
/// a filled − n + stepper once it is.
///
/// The pill is 36dp tall but every tap target is 48dp. With [allowZero] false the stepper's minus
/// stops being offered at 1 (use it where removing needs its own action).
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

  /// Read out by screen readers: "Shirt, 3 in basket".
  final String name;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  /// False at the per-item limit: the plus is disabled.
  final bool canAdd;

  /// Basket rows always show the stepper, even at zero.
  final bool showAddWhenEmpty;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;

    if (quantity == 0 && showAddWhenEmpty) {
      return Semantics(
        button: true,
        label: 'Add $name',
        excludeSemantics: true,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onAdd,
          child: SizedBox(
            height: IdSize.touchTarget,
            child: Center(
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(IdRadius.full),
                  border: Border.all(color: c.primary, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ADD', style: t.label.copyWith(color: c.primary, fontWeight: FontWeight.w700)),
                    const SizedBox(width: IdSpace.s1),
                    Icon(LucideIcons.plus, size: IdSize.iconSm, color: c.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: '$name, $quantity in basket',
      child: SizedBox(
        height: IdSize.touchTarget,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              top: 6,
              bottom: 6,
              child: DecoratedBox(decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(IdRadius.full))),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepButton(icon: LucideIcons.minus, label: 'Remove one $name', onTap: onRemove),
                ExcludeSemantics(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 24),
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.center,
                      style: t.label.copyWith(color: c.onPrimary, fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                ),
                _StepButton(icon: LucideIcons.plus, label: 'Add one $name', onTap: canAdd ? onAdd : null),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: IdSize.touchTarget,
          child: Icon(icon, size: IdSize.iconSm, color: onTap == null ? c.onPrimary.withValues(alpha: 0.5) : c.onPrimary),
        ),
      ),
    );
  }
}
