import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/order_timeline.dart';
import '../theme.dart';

/// The vertical progress list on an order: done steps filled with a tick, the current one ringed,
/// later ones hollow, joined by a line that fills as steps complete.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final current = steps.indexWhere((s) => s.state == ProgressState.current);
    return Semantics(
      container: true,
      label: current < 0 ? 'Order progress, complete' : 'Order progress, step ${current + 1} of ${steps.length}: ${steps[current].title}',
      child: Column(
        children: [
          for (final (i, step) in steps.indexed)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 28,
                    child: Column(
                      children: [
                        _Dot(step.state),
                        if (i < steps.length - 1)
                          Expanded(child: Container(width: 2, color: step.state == ProgressState.done ? c.primary : c.border)),
                      ],
                    ),
                  ),
                  const SizedBox(width: IdSpace.s3),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 3, bottom: i < steps.length - 1 ? 20 : 0),
                      child: MergeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: t.label.copyWith(
                                fontWeight: step.state == ProgressState.future ? FontWeight.w500 : FontWeight.w600,
                                color: step.state == ProgressState.future ? c.textMuted : c.text,
                              ),
                            ),
                            if (step.meta != null) Text(step.meta!, style: t.caption.copyWith(color: c.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.state);
  final ProgressState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return switch (state) {
      ProgressState.done => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
          child: Icon(LucideIcons.check, size: IdSize.iconSm, color: c.onPrimary),
        ),
      ProgressState.current => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.surface,
            border: Border.all(color: c.primary, width: 2),
            boxShadow: [BoxShadow(color: c.primarySoft, spreadRadius: 4)],
          ),
          child: Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle))),
        ),
      ProgressState.future => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.surface, border: Border.all(color: c.borderStrong, width: 2)),
        ),
    };
  }
}
