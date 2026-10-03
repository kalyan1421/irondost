import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/money.dart';
import '../theme.dart';
import 'id_button.dart';

/// Pinned above the bottom edge once the basket has something in it: item count, running total
/// and the button to the basket. Rises into place; nothing is reserved for it when the basket is empty.
class CartBar extends StatelessWidget {
  const CartBar({super.key, required this.count, required this.totalPaise, required this.onReview});

  /// Pieces in the basket. Zero hides the bar.
  final int count;
  final num totalPaise;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return AnimatedSize(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: count == 0
          ? const SizedBox(width: double.infinity)
          : DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(IdRadius.xl)),
                boxShadow: context.shadows.sheet,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s3, IdSpace.s4, IdSpace.s3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          label: '$count ${count == 1 ? 'item' : 'items'}, ${rupees(totalPaise)}',
                          excludeSemantics: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$count ${count == 1 ? 'item' : 'items'}', style: t.label.copyWith(color: c.textMuted)),
                              Text(rupees(totalPaise), style: t.titleLg),
                            ],
                          ),
                        ),
                      ),
                      IdButton(label: 'Review basket', icon: LucideIcons.chevronRight, iconAtEnd: true, onPressed: onReview),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
