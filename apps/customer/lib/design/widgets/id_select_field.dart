import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';
import 'choice_card.dart';
import 'id_sheet.dart';
import 'id_text_field.dart';

/// The design system's picker: label above, the field styled like [IdTextField], and the choices in a bottom sheet
/// (the same sheet and selectable rows as the rest of the app) instead of the platform dropdown.
class IdSelectField<T> extends StatelessWidget {
  const IdSelectField({
    super.key,
    required this.label,
    required this.sheetTitle,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint = 'Choose one',
    this.error,
    this.enabled = true,
  });

  final String label;

  /// The heading of the sheet that lists the choices.
  final String sheetTitle;

  /// Value to the words shown for it, in the order they are listed.
  final Map<T, String> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final String hint;
  final String? error;
  final bool enabled;

  Future<void> _open(BuildContext context) async {
    final picked = await showIdSheet<T>(
      context,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(sheetTitle, style: sheet.text.titleLg),
          ),
          const SizedBox(height: IdSpace.s4),
          for (final entry in options.entries) ...[
            ChoiceCard(
              title: entry.value,
              selected: entry.key == value,
              onTap: () => Navigator.of(sheet).pop(entry.key),
            ),
            const SizedBox(height: IdSpace.s2),
          ],
        ],
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final chosen = value == null ? null : options[value as T];
    final radius = BorderRadius.circular(IdRadius.md);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: t.labelSm),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          value: chosen ?? hint,
          excludeSemantics: true,
          onTap: enabled ? () => _open(context) : null,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? () => _open(context) : null,
            child: InputDecorator(
              isEmpty: chosen == null,
              decoration: InputDecoration(
                hintText: hint,
                enabled: enabled,
                error: error == null ? null : IdFieldError(error!),
                suffixIcon: Icon(
                  LucideIcons.chevronDown,
                  size: IdSize.iconMd,
                  color: c.textMuted,
                ),
              ),
              child: chosen == null
                  ? null
                  : Text(
                      chosen,
                      style: t.bodyLg.copyWith(color: enabled ? c.text : c.textMuted),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
