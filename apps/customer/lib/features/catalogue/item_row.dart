import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/money.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/item_stepper.dart';
import '../basket/basket.dart';
import 'catalogue.dart';

/// Puts one more of [itemId] in the basket, and says so when a limit stops it.
void addToBasket(BuildContext context, WidgetRef ref, String itemId) {
  final result = ref.read(basketProvider.notifier).add(itemId);
  final message = switch (result) {
    AddResult.added => null,
    AddResult.itemLimit => 'You can add up to ${BasketController.maxPerItem} of one item.',
    AddResult.basketFull => 'A basket holds up to ${BasketController.maxLines} different items.',
  };
  if (message != null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// A price-list row: thumbnail, name, price, unit and the add/stepper control.
class ItemRow extends ConsumerWidget {
  const ItemRow({super.key, required this.item, this.categoryName});

  final CatalogItemDto item;

  /// Shown after the unit in search results, where the same garment appears under several services.
  final String? categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final quantity = ref.watch(basketProvider.select((b) => b.quantityOf(item.id)));
    final hasOffer = item.offerPricePaise != null && item.offerPricePaise! < item.pricePaise;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: IdSpace.s3),
      child: Row(
        children: [
          _Thumb(item.imageUrl),
          const SizedBox(width: IdSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: t.title),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: rupees(item.effectivePricePaise),
                    style: t.label.copyWith(fontWeight: FontWeight.w600),
                    children: [
                      if (hasOffer)
                        TextSpan(
                          text: '  ${rupees(item.pricePaise)}',
                          style: t.label.copyWith(color: c.textMuted, decoration: TextDecoration.lineThrough),
                        ),
                    ],
                  ),
                  semanticsLabel: hasOffer
                      ? '${rupees(item.effectivePricePaise)}, was ${rupees(item.pricePaise)}'
                      : rupees(item.effectivePricePaise),
                ),
                Text(
                  [unitLabel(item.unit), ?categoryName].join(' · '),
                  style: t.caption.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: IdSpace.s2),
          ItemStepper(
            name: item.name,
            quantity: quantity,
            canAdd: quantity < BasketController.maxPerItem,
            onAdd: () => addToBasket(context, ref, item.id),
            onRemove: () => ref.read(basketProvider.notifier).remove(item.id),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb(this.url);
  final String? url;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icon = Icon(LucideIcons.shirt, size: IdSize.iconLg, color: c.primary);
    return ExcludeSemantics(
      child: Container(
        width: IdSize.thumb,
        height: IdSize.thumb,
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.surfaceSoft, borderRadius: BorderRadius.circular(IdRadius.sm)),
        child: url == null
            ? icon
            : Image.network(
                url!,
                width: IdSize.thumb,
                height: IdSize.thumb,
                fit: BoxFit.cover,
                cacheWidth: 168,
                errorBuilder: (_, _, _) => icon,
                loadingBuilder: (_, child, progress) => progress == null ? child : icon,
              ),
      ),
    );
  }
}
