import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/money.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/item_stepper.dart';
import '../../design/widgets/surfaces.dart';
import '../catalogue/catalogue.dart';
import '../catalogue/item_row.dart';
import 'basket.dart';
import 'promo_sheet.dart';
import 'quote.dart';
import 'quote_bill.dart';

/// The basket: items by service with steppers, an optional promo code, and the server's bill.
/// "Choose pickup time" is offered once the server says the basket can be booked.
class BasketScreen extends ConsumerWidget {
  const BasketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basket = ref.watch(basketProvider);
    final quote = ref.watch(quoteProvider);
    final q = quote.value;
    final loading = quote.isLoading;
    final failed = quote.hasError && !loading;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Text('Basket', style: context.text.titleLg),
      ),
      body: basket.isEmpty
          ? const _EmptyBasket()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                IdSpace.s5,
                IdSpace.s5,
                IdSpace.s5,
                IdSpace.s6,
              ),
              children: [
                _Items(basket: basket, quote: q),
                const SizedBox(height: IdSpace.s4),
                _PromoRow(code: basket.promoCode, quote: q, loading: loading),
                if (q?.minOrderShortfallPaise case final short?) ...[
                  const SizedBox(height: IdSpace.s4),
                  _MinOrderNotice(
                    shortfallPaise: short,
                    minOrderPaise: q!.subtotalPaise + short,
                  ),
                ],
                const SizedBox(height: IdSpace.s4),
                if (failed)
                  _QuoteFailure(onRetry: () => ref.invalidate(quoteProvider))
                else ...[
                  QuoteBill(quote: q, loading: loading, pieces: basket.count),
                  const SizedBox(height: IdSpace.s3),
                  Text(
                    'The final amount changes only if the count differs at pickup.',
                    style: context.text.caption.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: basket.isEmpty
          ? null
          : _Footer(quote: q, loading: loading),
    );
  }
}

class _Line {
  const _Line({
    required this.id,
    required this.name,
    required this.unitPaise,
    required this.quantity,
  });
  final String id;
  final String name;
  final num unitPaise;
  final int quantity;
}

class _Items extends ConsumerWidget {
  const _Items({required this.basket, required this.quote});

  final Basket basket;
  final QuoteDto? quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    final c = context.colors;
    final services =
        ref.watch(servicesProvider).value ?? const <CatalogCategoryDto>[];
    final quoted = {
      for (final l in quote?.lines ?? const <QuoteLineDto>[])
        l.catalogItemId: l,
    };

    _Line? lineFor(String id, CatalogItemDto? item) {
      final qty = basket.quantityOf(id);
      if (item != null) {
        return _Line(
          id: id,
          name: item.name,
          unitPaise: item.effectivePricePaise,
          quantity: qty,
        );
      }
      final line = quoted[id];
      return line == null
          ? null
          : _Line(
              id: id,
              name: line.name,
              unitPaise: line.unitPricePaise,
              quantity: qty,
            );
    }

    // Services in the admin's order, then anything the price list no longer shows (priced by the quote).
    final groups = <(String?, List<_Line>)>[];
    final placed = <String>{};
    for (final category in services) {
      final lines = [
        for (final item in category.items)
          if (basket.lines.containsKey(item.id)) ?lineFor(item.id, item),
      ];
      placed.addAll(lines.map((l) => l.id));
      if (lines.isNotEmpty) groups.add((category.name, lines));
    }
    final rest = [
      for (final id in basket.lines.keys.where((id) => !placed.contains(id)))
        ?lineFor(id, null),
    ];
    if (rest.isNotEmpty) groups.add((null, rest));

    return IdCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (name, lines) in groups) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: IdSpace.s3,
                bottom: IdSpace.s1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (name != null)
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(name, style: t.title),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: IdSpace.s2),
                  Text(
                    _pieces(lines.fold(0, (a, l) => a + l.quantity)),
                    style: t.caption.copyWith(color: c.textMuted),
                  ),
                ],
              ),
            ),
            for (final (i, line) in lines.indexed) ...[
              if (i > 0) const Divider(height: 1),
              _BasketRow(line: line),
            ],
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: IdButton.text(
              label: 'Add more items',
              icon: LucideIcons.plus,
              onPressed: () =>
                  context.canPop() ? context.pop() : context.push(Routes.book),
            ),
          ),
        ],
      ),
    );
  }

  static String _pieces(int n) => '$n ${n == 1 ? 'item' : 'items'}';
}

class _BasketRow extends ConsumerWidget {
  const _BasketRow({required this.line});
  final _Line line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    return Padding(padding: const EdgeInsets.symmetric(vertical: IdSpace.s4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(line.name, style: t.title), Text('${rupees(line.unitPaise)} each', style: t.caption.copyWith(color: c.textMuted))])),
        const SizedBox(width: IdSpace.s3),
        // Not Flexible: next to the Expanded name it would take half the row and start mid-screen.
        Text(rupees(line.unitPaise * line.quantity), textAlign: TextAlign.end, style: t.label.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
      const SizedBox(height: IdSpace.s3),
      ItemStepper(name: line.name, quantity: line.quantity, showAddWhenEmpty: false, canAdd: line.quantity < BasketController.maxPerItem,
        onAdd: () => addToBasket(context, ref, line.id),
        onRemove: () {
          final basket = ref.read(basketProvider.notifier)..remove(line.id);
          if (line.quantity == 1) {
            ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text('Removed ${line.name}'), action: SnackBarAction(label: 'Undo', onPressed: () => basket.add(line.id))));
          }
        },
      ),
    ]));
  }
}

/// "Apply a promo code", or the applied code with what the server made of it.
class _PromoRow extends ConsumerWidget {
  const _PromoRow({
    required this.code,
    required this.quote,
    required this.loading,
  });

  final String? code;
  final QuoteDto? quote;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    void open() => showPromoSheet(context);

    if (code == null) {
      return IdCard(
        onTap: open,
        padding: const EdgeInsets.symmetric(
          horizontal: IdSpace.s5,
          vertical: 14,
        ),
        child: Semantics(
          button: true,
          label: 'Apply a promo code',
          excludeSemantics: true,
          child: Row(
            children: [
              Icon(LucideIcons.badgePercent, size: IdSize.iconMd, color: c.textMuted),
              const SizedBox(width: IdSpace.s3),
              Expanded(child: Text('Apply a promo code', style: t.title)),
              Icon(
                LucideIcons.chevronRight,
                size: IdSize.iconSm,
                color: c.textMuted,
              ),
            ],
          ),
        ),
      );
    }

    final error = loading
        ? null
        : promoErrorText(
            quote?.promoError,
            shortfallPaise: quote?.promoShortfallPaise,
          );
    final applied =
        !loading &&
        quote != null &&
        quote!.promoCode == code &&
        quote!.promoError == null;

    if (error != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: IdSpace.s5,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(IdRadius.lg),
          border: Border.all(color: c.danger, width: 2),
        ),
        child: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              _Tile(LucideIcons.badgePercent, c.dangerSoft, c.danger),
              const SizedBox(width: IdSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(code!, style: t.orderId),
                    Text(error, style: t.caption.copyWith(color: c.danger)),
                  ],
                ),
              ),
              IdButton.text(label: 'Change', onPressed: open),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: IdSpace.s3),
      decoration: BoxDecoration(
        color: c.successSoft,
        borderRadius: BorderRadius.circular(IdRadius.md),
      ),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(
              LucideIcons.badgePercent,
              size: IdSize.iconMd,
              color: c.success,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: code,
                      style: t.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: applied
                          ? ' applied. You save ${rupees(quote!.discountPaise)}.'
                          : ' · checking…',
                    ),
                  ],
                ),
                style: t.body,
              ),
            ),
            IdButton.text(label: 'Change', onPressed: open),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.bg, this.fg);
  final IconData icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(IdRadius.sm),
    ),
    child: Icon(icon, size: IdSize.iconMd, color: fg),
  );
}

class _MinOrderNotice extends StatelessWidget {
  const _MinOrderNotice({
    required this.shortfallPaise,
    required this.minOrderPaise,
  });
  final num shortfallPaise;
  final num minOrderPaise;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: IdSpace.s3,
        ),
        decoration: BoxDecoration(
          color: c.warningSoft,
          borderRadius: BorderRadius.circular(IdRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: IdSize.iconMd,
              color: c.warning,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Add '),
                    TextSpan(
                      text: rupees(shortfallPaise),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          ' more to book. The minimum order is ${rupees(minOrderPaise)}.',
                    ),
                  ],
                ),
                style: t.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteFailure extends ConsumerWidget {
  const _QuoteFailure({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    return IdCard(
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(LucideIcons.circleAlert, color: c.danger),
            const SizedBox(width: IdSpace.s3),
            Expanded(
              child: Text(
                "Couldn't work out the total. Check your connection.",
                style: t.body,
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.quote, required this.loading});

  final QuoteDto? quote;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final q = quote;
    final short = q?.minOrderShortfallPaise;
    // With large text the total and the button no longer fit side by side: the button goes below,
    // full width (the same rule as the catalogue's cart bar).
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final IdButton button;
    if (short != null && !loading) {
      button = IdButton(
        label: 'Add ${rupees(short)} more',
        expand: stacked,
        onPressed: () =>
            context.canPop() ? context.pop() : context.push(Routes.book),
      );
    } else {
      button = IdButton(
        label: 'Choose pickup time',
        expand: stacked,
        onPressed: q != null && q.canPlaceOrder && !loading
            ? () => context.push(Routes.schedule)
            : null,
      );
    }
    // Always shown, so the button does not change width while a new price is on its way: the last
    // total stays, muted, until the server answers.
    final total = q == null ? '—' : rupees(q.totalPaise);
    final summary = Semantics(
      label: q == null ? 'Total not known yet' : 'Total $total',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Total', style: t.label.copyWith(color: c.textMuted)),
          Text(
            total,
            style: t.titleLg.copyWith(
              color: loading ? c.textMuted : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
    return DecoratedBox(
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
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [summary, const SizedBox(height: IdSpace.s2), button],
                )
              : Row(
                  children: [
                    Expanded(child: summary),
                    const SizedBox(width: IdSpace.s3),
                    button,
                  ],
                ),
        ),
      ),
    );
  }
}

class _EmptyBasket extends StatelessWidget {
  const _EmptyBasket();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(IdSpace.s6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: c.surfaceSoft,
                        shape: BoxShape.circle,
                      ),
                      child: ExcludeSemantics(
                        child: Icon(
                          LucideIcons.shoppingBag,
                          size: 32,
                          color: c.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: IdSpace.s4),
              Semantics(
                header: true,
                child: Text(
                  'Your basket is empty',
                  style: t.titleLg,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: IdSpace.s2),
              Text(
                'Add the clothes you want ironed, washed or dry-cleaned. A rough count is fine.',
                style: t.bodyLg.copyWith(color: c.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: IdSpace.s4),
              IdButton(
                label: 'Choose items',
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.push(Routes.book),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
