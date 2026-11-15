import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/money.dart';
import '../../core/order_text.dart';
import '../../core/slots.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/surfaces.dart';

/// Each refund once: the amount and where it stands on the first line, then where it goes and when, then the note.
/// Nothing here repeats what the order says elsewhere.
class RefundList extends StatelessWidget {
  const RefundList({super.key, required this.order});
  final OrderDto order;

  @override
  Widget build(BuildContext context) {
    final refunds = order.refunds ?? const <RefundDto>[];
    if (refunds.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(refunds.length == 1 ? 'Refund' : 'Refunds', style: context.text.title)),
        IdCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < refunds.length; i++) ...[
                if (i > 0) Divider(height: 1, color: context.colors.border),
                Padding(padding: const EdgeInsets.symmetric(vertical: IdSpace.s3), child: _RefundRow(refunds[i])),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RefundRow extends StatelessWidget {
  const _RefundRow(this.refund);
  final RefundDto refund;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final note = refund.note.trim();
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: IdSpace.s3,
            runSpacing: IdSpace.s1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [Text(rupees(refund.amountPaise), style: t.titleLg), _RefundChip(refund.status)],
          ),
          const SizedBox(height: IdSpace.s1),
          Text('${refundMethod(refund.method)} · ${istDateTimeLabel(refund.processedAt ?? refund.createdAt)}',
            style: t.body.copyWith(color: c.textMuted)),
          if (note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: IdSpace.s1), child: Text(note, style: t.body)),
          if (refund.status == RefundStatus.failed)
            Padding(
              padding: const EdgeInsets.only(top: IdSpace.s1),
              child: Text('The refund did not complete. Contact support.', style: t.body.copyWith(color: c.danger)),
            ),
        ],
      ),
    );
  }
}

/// A refund's state as a small pill that is only as wide as its words.
class _RefundChip extends StatelessWidget {
  const _RefundChip(this.status);
  final RefundStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, icon) = switch (status) {
      RefundStatus.pending => (c.primarySoft, c.onPrimarySoft, LucideIcons.clock),
      RefundStatus.processed => (c.successSoft, c.success, LucideIcons.check),
      RefundStatus.failed => (c.dangerSoft, c.danger, LucideIcons.circleAlert),
      RefundStatus.$unknown => (c.surfaceSoft, c.textMuted, null),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(IdRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: IdSize.iconSm, color: fg), const SizedBox(width: IdSpace.s1)],
          Flexible(child: Text(refundState(status), style: context.text.labelSm.copyWith(color: fg))),
        ],
      ),
    );
  }
}
