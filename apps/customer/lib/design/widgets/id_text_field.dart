import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';

/// The design system's TextField: label above the field (never only a placeholder),
/// helper text below, and errors under the field with an icon.
class IdTextField extends StatelessWidget {
  const IdTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.help,
    this.error,
    this.prefixText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.trailing,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final String? help;
  final String? error;

  /// Fixed text before the value, e.g. "+91" on the phone field.
  final String? prefixText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final prefix = prefixText == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(prefixText!, style: t.bodyLg.copyWith(color: c.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                Container(width: 1, height: 24, color: c.border),
                const SizedBox(width: 10),
              ],
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: t.labelSm),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: t.bodyLg,
          decoration: InputDecoration(
            hintText: hint,
            helperText: error == null ? help : null,
            prefixIcon: prefix,
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: trailing,
            error: error == null
                ? null
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(LucideIcons.circleAlert, size: IdSize.iconSm, color: c.danger),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(error!, style: t.caption.copyWith(color: c.danger))),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
