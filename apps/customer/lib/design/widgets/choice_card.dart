import 'package:flutter/material.dart';

import '../theme.dart';

/// A selectable option with an icon, title, description and radio: "Pay online" / "Cash on delivery".
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({super.key, required this.icon, required this.title, required this.description, required this.selected, required this.onTap});

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final radius = BorderRadius.circular(IdRadius.lg);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: '$title. $description',
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: selected ? c.primary : c.border, width: selected ? 2 : 1)),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: IdSpace.s4, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: c.surfaceSoft, borderRadius: BorderRadius.circular(IdRadius.sm)),
                  child: Icon(icon, size: IdSize.iconMd, color: c.primary),
                ),
                const SizedBox(width: IdSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: t.title),
                      Text(description, style: t.body.copyWith(color: c.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: IdSpace.s2),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? c.primary : c.borderStrong, width: selected ? 6 : 2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
