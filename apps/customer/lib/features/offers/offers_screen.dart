import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/surfaces.dart';
import 'promotions.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final promos = ref.watch(promotionsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Offers', style: t.headline)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(promotionsProvider.future).catchError((_) => <PromotionDto>[]),
        child: promos.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(IdSpace.s8),
            children: [
              Text("Couldn't load offers. Pull down to try again.", style: t.body.copyWith(color: c.textMuted), textAlign: TextAlign.center),
            ],
          ),
          data: (list) => list.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(IdSpace.s8),
                  children: [
                    const SizedBox(height: IdSpace.s12),
                    Icon(LucideIcons.badgePercent, size: 52, color: c.textMuted),
                    const SizedBox(height: IdSpace.s4),
                    Text('No offers right now', style: t.titleLg, textAlign: TextAlign.center),
                    const SizedBox(height: IdSpace.s2),
                    Text(
                      "New offers show up here, and we'll let you know when one starts.",
                      style: t.body.copyWith(color: c.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(IdSpace.s4),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: IdSpace.s3),
                  itemBuilder: (context, i) => _PromoTile(list[i]),
                ),
        ),
      ),
    );
  }
}

class _PromoTile extends StatelessWidget {
  const _PromoTile(this.promo);
  final PromotionDto promo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final terms = promoTerms(promo, withValidity: true);
    return IdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(promo.title, style: t.title),
          if (promo.description != null) ...[
            const SizedBox(height: IdSpace.s1),
            Text(promo.description!, style: t.body),
          ],
          const SizedBox(height: IdSpace.s1),
          Text(terms, style: t.caption.copyWith(color: c.textMuted)),
          const SizedBox(height: IdSpace.s3),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(IdRadius.sm),
                  border: Border.all(color: c.text, width: 1.5),
                ),
                child: Text(promo.code, style: t.orderId),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: promo.code));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Code ${promo.code} copied')));
                },
                child: const Text('Copy code'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
