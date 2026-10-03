import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/order_status.dart';
import '../../data/api/export.dart';
import '../theme.dart';

/// An order's status in the customer's words, coloured by tone. Never pass free text.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, icon) = switch (status.tone) {
      StatusTone.info => (c.primarySoft, c.onPrimarySoft, null),
      StatusTone.accent => (c.surfaceSoft, c.accent, LucideIcons.truck),
      StatusTone.success => (c.successSoft, c.success, LucideIcons.check),
      StatusTone.neutral => (c.surfaceSoft, c.textMuted, null),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(IdRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: IdSize.iconSm, color: fg), const SizedBox(width: IdSpace.s1)],
          Flexible(child: Text(status.customerLabel, style: context.text.labelSm.copyWith(color: fg))),
        ],
      ),
    );
  }
}
