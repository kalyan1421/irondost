import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/phone.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/cart_bar.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/surfaces.dart';
import '../basket/basket.dart';
import '../support/support.dart';
import 'catalogue.dart';
import 'item_row.dart';

/// Search across every service. A garment listed under two services shows both, labelled.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final services = ref.watch(servicesProvider).value ?? const <CatalogCategoryDto>[];
    final query = _controller.text.trim().toLowerCase();
    final hits = [
      for (final category in services)
        for (final item in category.items)
          if (query.isEmpty || item.name.toLowerCase().contains(query)) (category, item),
    ];
    final count = ref.watch(basketCountProvider);
    final estimate = ref.watch(basketEstimateProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: IdSpace.s4),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search shirt, saree, bedsheet…',
              prefixIcon: Icon(LucideIcons.search, size: IdSize.iconMd, color: c.textMuted),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(LucideIcons.x, size: IdSize.iconMd),
                      tooltip: 'Clear search',
                      onPressed: () => setState(_controller.clear),
                    ),
            ),
          ),
        ),
      ),
      body: hits.isEmpty && query.isNotEmpty
          ? _NoResults(query: _controller.text.trim(), services: services, onPick: (name) => setState(() => _controller.text = name))
          : ListView(
              padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s2, IdSpace.s4, IdSpace.s6),
              children: [
                if (hits.isNotEmpty)
                  IdCard(
                    padding: const EdgeInsets.symmetric(horizontal: IdSpace.s4),
                    child: Column(
                      children: [
                        for (final (i, (category, item)) in hits.indexed) ...[
                          if (i > 0) const Divider(height: 1),
                          ItemRow(key: ValueKey(item.id), item: item, categoryName: category.name),
                        ],
                      ],
                    ),
                  ),
                if (hits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(IdSpace.s6),
                    child: Text('Prices are loading…', style: t.body.copyWith(color: c.textMuted), textAlign: TextAlign.center),
                  ),
              ],
            ),
      bottomNavigationBar: CartBar(count: count, totalPaise: estimate, onReview: () => context.push(Routes.basket)),
    );
  }
}

class _NoResults extends ConsumerWidget {
  const _NoResults({required this.query, required this.services, required this.onPick});

  final String query;
  final List<CatalogCategoryDto> services;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final popular = <String>{
      for (final category in services)
        for (final item in category.items.take(2)) item.name,
    }.take(4).toList();
    final phone = Support.of(ref).phone;

    return ListView(
      padding: const EdgeInsets.all(IdSpace.s4),
      children: [
        Semantics(
          liveRegion: true,
          child: Column(
            children: [
              const SizedBox(height: IdSpace.s6),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: c.surfaceSoft, shape: BoxShape.circle),
                child: Icon(LucideIcons.search, size: 44, color: c.textMuted),
              ),
              const SizedBox(height: IdSpace.s4),
              Text('No items match "$query"', style: t.titleLg, textAlign: TextAlign.center),
              const SizedBox(height: IdSpace.s2),
              Text(
                "Try a different word, like shirt or saree. Need something we don't list? Call us and we'll help.",
                style: t.bodyLg.copyWith(color: c.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: IdSpace.s4),
              IdButton.outline(label: 'Call ${IndianPhone.display(phone)}', icon: LucideIcons.phone, onPressed: () => Support.dial(phone)),
            ],
          ),
        ),
        if (popular.isNotEmpty) ...[
          const SizedBox(height: IdSpace.s8),
          Semantics(header: true, child: Text('Popular', style: t.labelSm.copyWith(color: c.textMuted))),
          const SizedBox(height: IdSpace.s3),
          Wrap(
            spacing: IdSpace.s2,
            runSpacing: IdSpace.s2,
            children: [
              for (final name in popular)
                ActionChip(
                  label: Text(name),
                  onPressed: () => onPick(name),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
