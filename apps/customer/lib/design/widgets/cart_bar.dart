import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/money.dart';
import '../theme.dart';
import 'id_button.dart';

/// Pinned above the bottom edge once the basket has something in it: item count, running total
/// and the button to the basket. Rises into place; nothing is reserved for it when the basket is empty.
class CartBar extends StatelessWidget {
  const CartBar({
    super.key,
    required this.count,
    required this.totalPaise,
    required this.onReview,
  });

  /// Pieces in the basket. Zero hides the bar.
  final int count;
  final num totalPaise;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return AnimatedSize(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: count == 0
          ? const SizedBox(width: double.infinity)
          : DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    IdSpace.s5,
                    IdSpace.s3,
                    IdSpace.s5,
                    IdSpace.s3,
                  ),
                  child: Builder(
                    builder: (context) {
                      final summary = Semantics(
                        liveRegion: true,
                        label:
                            '$count ${count == 1 ? 'item' : 'items'}, ${rupees(totalPaise)}',
                        excludeSemantics: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$count ${count == 1 ? 'item' : 'items'}',
                              style: t.label.copyWith(color: c.textMuted),
                            ),
                            Text(rupees(totalPaise), style: t.titleLg),
                          ],
                        ),
                      );
                      // With large text the summary and the button no longer fit side by side, so the button goes below, full width.
                      final stacked =
                          MediaQuery.textScalerOf(context).scale(1) > 1.3;
                      final button = IdButton(
                        label: 'Review basket',
                        icon: LucideIcons.chevronRight,
                        iconAtEnd: true,
                        expand: stacked,
                        onPressed: onReview,
                      );
                      return stacked
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                summary,
                                const SizedBox(height: IdSpace.s2),
                                button,
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: summary),
                                button,
                              ],
                            );
                    },
                  ),
                ),
              ),
            ),
    );
  }
}
