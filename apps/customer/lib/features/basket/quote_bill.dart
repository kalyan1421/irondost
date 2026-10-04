import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/surfaces.dart';

/// The server's bill for a basket: items, discount, delivery and what to pay. Dimmed while a new
/// quote loads, a skeleton before the first one.
class QuoteBill extends StatelessWidget {
  const QuoteBill({
    super.key,
    required this.quote,
    required this.loading,
    required this.pieces,
  });

  final QuoteDto? quote;
  final bool loading;
  final int pieces;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final q = quote;
    final figures = [const FontFeature.tabularFigures()];

    Widget row(
      String label,
      String value, {
      Color? color,
      FontWeight? weight,
    }) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: t.bodyLg.copyWith(color: color, fontWeight: weight),
          ),
        ),
        const SizedBox(width: IdSpace.s3),
        Text(
          value,
          style: t.bodyLg.copyWith(
            color: color,
            fontWeight: weight,
            fontFeatures: figures,
          ),
        ),
      ],
    );

    if (q == null) {
      // First price still on its way.
      return IdCard(
        child: Semantics(
          label: 'Working out the bill',
          child: ExcludeSemantics(
            child: Column(
              children: [
                for (final w in [140.0, 120.0, 160.0]) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: w,
                      height: 16,
                      decoration: BoxDecoration(
                        color: c.surfaceSoft,
                        borderRadius: BorderRadius.circular(IdRadius.sm),
                      ),
                    ),
                  ),
                  const SizedBox(height: IdSpace.s3),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return AnimatedOpacity(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 150),
      opacity: loading ? 0.5 : 1,
      child: IdCard(
        child: Semantics(
          label: 'Bill, to pay ${rupees(q.totalPaise)}',
          child: Column(
            children: [
              row('Items ($pieces)', rupees(q.subtotalPaise)),
              if (q.discountPaise > 0) ...[
                const SizedBox(height: 10),
                row(
                  q.promoCode ?? 'Discount',
                  '−${rupees(q.discountPaise)}',
                  color: c.success,
                  weight: FontWeight.w600,
                ),
              ],
              const SizedBox(height: 10),
              row(
                'Pickup & delivery',
                q.deliveryFeePaise == 0 ? 'Free' : rupees(q.deliveryFeePaise),
                color: c.textMuted,
              ),
              const SizedBox(height: IdSpace.s3),
              Container(
                padding: const EdgeInsets.only(top: IdSpace.s3),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.borderStrong)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('To pay', style: t.titleLg),
                    Text(
                      rupees(q.totalPaise),
                      style: t.titleLg.copyWith(fontFeatures: figures),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
