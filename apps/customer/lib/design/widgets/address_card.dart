import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/api/export.dart';
import '../theme.dart';

IconData addressIcon(String label) => switch (label.trim().toLowerCase()) {
  'home' => LucideIcons.house,
  'work' || 'office' => LucideIcons.briefcase,
  _ => LucideIcons.mapPin,
};

/// A saved address, in the address book and the picker.
///
/// [selected] draws the 2dp primary border and radio; [onEdit] adds the pencil button.
/// An address outside the service area stays visible with a "Not in our area yet" chip.
class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    this.selected,
    this.onTap,
    this.onEdit,
  });

  final AddressDto address;

  /// Null in the address book (no radio); true/false in the picker.
  final bool? selected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final isSelected = selected ?? false;
    final radius = BorderRadius.circular(IdRadius.lg);
    final unserved = !address.serviceable;

    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Opacity(
        opacity: 1,
        child: Material(
          color: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: isSelected ? c.primary : c.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: IdSpace.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(addressIcon(address.label), size: IdSize.iconMd, color: c.textMuted),
                  const SizedBox(width: IdSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: IdSpace.s2,
                          runSpacing: IdSpace.s1,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(address.label, style: t.title),
                            if (address.isPrimary)
                              _Chip('Default', c.primarySoft, c.onPrimarySoft),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          address.formatted,
                          style: t.body.copyWith(color: c.textMuted),
                        ),
                        if (unserved) ...[
                          const SizedBox(height: IdSpace.s2),
                          _Chip(
                            'Not in our area yet',
                            c.surfaceSoft,
                            c.textMuted,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (selected != null)
                    Padding(
                      padding: const EdgeInsets.only(left: IdSpace.s2, top: 10),
                      child: _Radio(isSelected),
                    ),
                  if (onEdit != null)
                    SizedBox.square(
                      dimension: IdSize.touchTarget,
                      child: IconButton(
                        icon: const Icon(LucideIcons.pencil),
                        tooltip: 'Edit ${address.label} address',
                        onPressed: onEdit,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.bg, this.fg);
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 24),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(IdRadius.sm),
    ),
    // widthFactor keeps the chip as wide as its text inside a Wrap.
    child: Center(
      widthFactor: 1,
      child: Text(text, style: context.text.labelSm.copyWith(color: fg)),
    ),
  );
}

class _Radio extends StatelessWidget {
  const _Radio(this.on);
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: on ? c.primary : c.borderStrong,
          width: on ? 6 : 2,
        ),
      ),
    );
  }
}
