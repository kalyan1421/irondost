import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/cart_bar.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/surfaces.dart';
import '../basket/basket.dart';
import 'catalogue.dart';
import 'item_row.dart';

/// "Choose items": one tab per service (Ironing, Wash & iron, Dry cleaning), prices and the
/// add/stepper control, and the cart bar once something is in the basket.
///
/// [service] is a category slug from Home; it picks the first tab.
class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key, this.service});

  final String? service;

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  String? _selectedSlug;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final services = ref.watch(servicesProvider);
    final count = ref.watch(basketCountProvider);
    final estimate = ref.watch(basketEstimateProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home)),
        title: Text('Choose items', style: t.titleLg),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search),
            tooltip: 'Search items',
            onPressed: () => context.push(Routes.bookSearch),
          ),
        ],
      ),
      body: services.when(
        loading: () => const _Loading(),
        error: (e, _) => _LoadFailure(onRetry: () => ref.invalidate(catalogProvider)),
        data: (list) {
          if (list.isEmpty) return const _NoServices();
          final selected = list.firstWhere(
            (c) => c.slug == (_selectedSlug ?? widget.service),
            orElse: () => list.first,
          );
          return Column(
            children: [
              _ServiceTabs(
                services: list,
                selected: selected,
                onSelect: (c) => setState(() => _selectedSlug = c.slug),
              ),
              Expanded(child: _Items(category: selected)),
            ],
          );
        },
      ),
      bottomNavigationBar: CartBar(count: count, totalPaise: estimate, onReview: () => context.push(Routes.basket)),
    );
  }
}

class _ServiceTabs extends StatelessWidget {
  const _ServiceTabs({required this.services, required this.selected, required this.onSelect});

  final List<CatalogCategoryDto> services;
  final CatalogCategoryDto selected;
  final ValueChanged<CatalogCategoryDto> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surface, border: Border(bottom: BorderSide(color: c.border))),
      child: SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: IdSpace.s4, vertical: IdSpace.s2),
          itemCount: services.length,
          separatorBuilder: (_, _) => const SizedBox(width: IdSpace.s2),
          itemBuilder: (_, i) {
            final category = services[i];
            final on = category.id == selected.id;
            return Semantics(
              button: true,
              selected: on,
              label: category.name,
              excludeSemantics: true,
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => onSelect(category),
                child: Center(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: IdSpace.s4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? c.primary : c.surface,
                      borderRadius: BorderRadius.circular(IdRadius.full),
                      border: on ? null : Border.all(color: c.borderStrong),
                    ),
                    child: Text(category.name, style: t.labelSm.copyWith(color: on ? c.onPrimary : c.text)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Items extends StatelessWidget {
  const _Items({required this.category});
  final CatalogCategoryDto category;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return ListView(
      padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s4, IdSpace.s4, IdSpace.s6),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: IdSpace.s3),
          decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(IdRadius.md)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.shirt, size: IdSize.iconMd, color: c.onPrimarySoft),
              const SizedBox(width: 10),
              Expanded(child: Text('A rough count is fine. Your partner confirms it at pickup.', style: t.body)),
            ],
          ),
        ),
        const SizedBox(height: IdSpace.s4),
        IdCard(
          padding: const EdgeInsets.symmetric(horizontal: IdSpace.s4),
          child: Column(
            children: [
              for (final (i, item) in category.items.indexed) ...[
                if (i > 0) const Divider(height: 1),
                ItemRow(key: ValueKey(item.id), item: item),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget block(double w, double h, {double radius = IdRadius.sm}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: c.surfaceSoft, borderRadius: BorderRadius.circular(radius)),
        );
    return Semantics(
      label: 'Loading prices',
      child: ExcludeSemantics(
        // A list that never scrolls, so the placeholder is cut off rather than overflowing when text is large.
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(IdSpace.s4),
          children: [
            Row(children: [block(88, 40, radius: IdRadius.full), const SizedBox(width: IdSpace.s2), block(104, 40, radius: IdRadius.full), const SizedBox(width: IdSpace.s2), block(104, 40, radius: IdRadius.full)]),
            const SizedBox(height: IdSpace.s6),
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: IdSpace.s4),
                child: Row(
                  children: [
                    block(IdSize.thumb, IdSize.thumb),
                    const SizedBox(width: IdSpace.s3),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [block(150, 16), const SizedBox(height: 8), block(70, 14)])),
                    block(76, 36, radius: IdRadius.full),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Couldn't load prices": the price list failed. The basket is untouched.
class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return ListView(
      padding: const EdgeInsets.all(IdSpace.s4),
      children: [
        IdCard(
          padding: const EdgeInsets.symmetric(horizontal: IdSpace.s5, vertical: IdSpace.s8),
          child: Semantics(
            liveRegion: true,
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: c.dangerSoft, shape: BoxShape.circle),
                  child: Icon(LucideIcons.circleAlert, size: IdSize.iconLg, color: c.danger),
                ),
                const SizedBox(height: IdSpace.s3),
                Text("Couldn't load prices", style: t.titleLg),
                const SizedBox(height: IdSpace.s2),
                Text(
                  'Check your connection and try again. Items already in your basket are kept.',
                  style: t.body.copyWith(color: c.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: IdSpace.s4),
                IdButton.tonal(label: 'Try again', icon: LucideIcons.refreshCw, onPressed: onRetry),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NoServices extends StatelessWidget {
  const _NoServices();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(IdSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.shirt, size: 52, color: c.textMuted),
            const SizedBox(height: IdSpace.s4),
            Text('No services right now', style: t.titleLg),
            const SizedBox(height: IdSpace.s2),
            Text("We're updating our price list. Please check back soon.", style: t.body.copyWith(color: c.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
