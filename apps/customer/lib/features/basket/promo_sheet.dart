import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_text_field.dart';
import '../offers/promotions.dart';
import 'basket.dart';
import 'quote.dart';

/// "Apply a code": type one, or pick from what is running. A code only sticks once the server
/// has priced the basket with it, so a bad code is explained here instead of in the bill.
Future<void> showPromoSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _PromoSheet(),
    );

class _PromoSheet extends ConsumerStatefulWidget {
  const _PromoSheet();

  @override
  ConsumerState<_PromoSheet> createState() => _PromoSheetState();
}

class _PromoSheetState extends ConsumerState<_PromoSheet> {
  final _code = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _apply(String raw) async {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Enter a code.');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    final basket = ref.read(basketProvider);
    String? error;
    try {
      final quote = await ref.read(quoteRepositoryProvider).quote(basket.items, code);
      error = promoErrorText(quote.promoError, shortfallPaise: quote.promoShortfallPaise);
    } on ApiFailure catch (e) {
      error = e.isConnectivity ? "You're offline. Check your connection and try again." : "Couldn't check the code. Please try again.";
    }
    if (!mounted) return;
    if (error == null) {
      ref.read(basketProvider.notifier).applyPromo(code);
      Navigator.pop(context);
      return;
    }
    setState(() {
      _checking = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final applied = ref.watch(basketProvider.select((b) => b.promoCode));
    final promos = ref.watch(promotionsProvider).value ?? const <PromotionDto>[];
    final subtotal = ref.watch(basketEstimateProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(IdSpace.s4, 0, IdSpace.s4, IdSpace.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text('Apply a code', style: t.titleLg)),
              const SizedBox(height: IdSpace.s4),
              IdTextField(
                label: 'Promo code',
                controller: _code,
                error: _error,
                autofocus: true,
                enabled: !_checking,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9_-]')), LengthLimitingTextInputFormatter(32)],
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: _apply,
                trailing: _checking
                    ? const Padding(padding: EdgeInsets.only(right: IdSpace.s3), child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    : TextButton(onPressed: () => _apply(_code.text), child: const Text('Apply')),
              ),
              if (applied != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IdButton.text(
                    label: 'Remove $applied',
                    onPressed: _checking
                        ? null
                        : () {
                            ref.read(basketProvider.notifier).applyPromo(null);
                            Navigator.pop(context);
                          },
                  ),
                ),
              if (promos.isNotEmpty) ...[
                const SizedBox(height: IdSpace.s6),
                Semantics(header: true, child: Text('Available for you', style: t.labelSm.copyWith(color: context.colors.textMuted))),
                const SizedBox(height: IdSpace.s3),
                for (final promo in promos) ...[
                  _PromoRow(promo: promo, subtotalPaise: subtotal, onApply: _checking ? null : () => _apply(promo.code)),
                  const SizedBox(height: IdSpace.s2),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoRow extends StatelessWidget {
  const _PromoRow({required this.promo, required this.subtotalPaise, required this.onApply});

  final PromotionDto promo;
  final num subtotalPaise;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final short = promo.minOrderPaise - subtotalPaise;
    final usable = short <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: IdSpace.s4, vertical: 14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(IdRadius.lg), border: Border.all(color: c.border)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(promo.code, style: t.orderId),
                Text(promo.title, style: t.body),
                if (usable)
                  Text(promoTerms(promo), style: t.caption.copyWith(color: c.textMuted))
                else
                  Text('Add ${rupees(short)} more to use this', style: t.caption.copyWith(color: c.warning)),
              ],
            ),
          ),
          const SizedBox(width: IdSpace.s3),
          IdButton.tonal(label: 'Apply', onPressed: usable ? onApply : null),
        ],
      ),
    );
  }
}
