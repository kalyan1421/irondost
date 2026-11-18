import 'package:flutter/material.dart';

import '../theme.dart';

/// A neutral outlined control that adds a ready-made phrase to a note. At least 48 dp tall, never a filled primary: the
/// one filled button on a screen is its main action. [selected] marks a phrase the note already holds.
class PhraseChip extends StatelessWidget {
  const PhraseChip({
    super.key,
    required this.label,
    required this.onTap,
    required this.semanticLabel,
    this.selected = false,
  });

  final String label;

  /// What a screen reader says, e.g. `Add "Starch" to the care note`.
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(IdRadius.md),
      side: BorderSide(color: selected ? c.primary : c.borderStrong),
    );
    return Semantics(
      button: true,
      label: semanticLabel,
      selected: selected,
      excludeSemantics: true,
      enabled: onTap != null,
      child: Material(
        color: selected ? c.primarySoft : c.surface,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: IdSize.touchTarget),
            // widthFactor 1: centre the label in the 48 dp target without stretching the chip to the full row.
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: IdSpace.s3,
                  vertical: IdSpace.s2,
                ),
                child: Text(
                  label,
                  style: context.text.label.copyWith(
                    color: selected ? c.onPrimarySoft : c.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
