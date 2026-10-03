import 'package:flutter/material.dart';

import '../theme.dart';
import 'id_button.dart';
import 'state_view.dart';

/// The design system's modal alert: a tinted icon, a title, a short explanation, one primary action
/// and one quiet one. Resolves true for the primary action, false for the other, null if dismissed.
Future<bool?> showIdAlert(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String body,
  required String primaryLabel,
  String? secondaryLabel,
  StateTone tone = StateTone.warning,
  bool barrierDismissible = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      final c = context.colors;
      final t = context.text;
      final (bg, fg) = switch (tone) {
        StateTone.neutral => (c.surfaceSoft, c.textMuted),
        StateTone.primary => (c.primarySoft, c.onPrimarySoft),
        StateTone.success => (c.successSoft, c.success),
        StateTone.warning => (c.warningSoft, c.warning),
        StateTone.danger => (c.dangerSoft, c.danger),
      };
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: IdSpace.s6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IdRadius.xl)),
        child: Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          namesRoute: true,
          label: title,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(IdSpace.s5, IdSpace.s6, IdSpace.s5, IdSpace.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, size: IdSize.iconLg, color: fg)),
                const SizedBox(height: IdSpace.s3),
                Text(title, style: t.titleLg, textAlign: TextAlign.center),
                const SizedBox(height: IdSpace.s2),
                Text(body, style: t.body.copyWith(color: c.textMuted), textAlign: TextAlign.center),
                const SizedBox(height: IdSpace.s4),
                IdButton(label: primaryLabel, expand: true, onPressed: () => Navigator.pop(context, true)),
                if (secondaryLabel != null) ...[
                  const SizedBox(height: IdSpace.s1),
                  IdButton.text(label: secondaryLabel, expand: true, onPressed: () => Navigator.pop(context, false)),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
