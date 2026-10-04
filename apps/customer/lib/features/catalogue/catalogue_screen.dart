import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/cart_bar.dart';
import '../../design/widgets/surfaces.dart';
import '../../design/widgets/service_visual.dart';
import '../basket/basket.dart';
import 'catalogue.dart';
import 'catalogue_states.dart';
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
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
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
        loading: () => const CatalogueLoading(),
        error: (e, _) => CatalogueFailure(
          failure: ApiFailure.from(e),
          onRetry: () => ref.invalidate(catalogProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return CatalogueEmpty(
              onRetry: () => ref.invalidate(catalogProvider),
            );
          }
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
      bottomNavigationBar: CartBar(
        count: count,
        totalPaise: estimate,
        onReview: () => context.push(Routes.basket),
      ),
    );
  }
}

class _ServiceTabs extends StatelessWidget {
  const _ServiceTabs({
    required this.services,
    required this.selected,
    required this.onSelect,
  });

  final List<CatalogCategoryDto> services;
  final CatalogCategoryDto selected;
  final ValueChanged<CatalogCategoryDto> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: IdSpace.s5,
            vertical: IdSpace.s2,
          ),
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
                borderRadius: BorderRadius.circular(IdRadius.sm),
                onTap: () => onSelect(category),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: IdSize.touchTarget,
                    ),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.zero,
                      border: Border(
                        bottom: BorderSide(
                          color: on ? c.primary : c.border,
                          width: on ? 2 : 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ServiceVisual(
                          category: category,
                          size: 28,
                          color: on ? c.primary : c.textMuted,
                        ),
                        const SizedBox(width: IdSpace.s2),
                        Text(
                          category.name,
                          style: t.labelSm.copyWith(
                            color: on ? c.primary : c.textMuted,
                          ),
                        ),
                      ],
                    ),
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
      padding: const EdgeInsets.fromLTRB(
        IdSpace.s5,
        IdSpace.s5,
        IdSpace.s5,
        IdSpace.s6,
      ),
      children: [
        Text(
          'A rough count is fine. Your partner confirms it at pickup.',
          style: t.caption.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: IdSpace.s4),
        IdCard(
          padding: EdgeInsets.zero,
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
