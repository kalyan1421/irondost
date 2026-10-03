import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/surfaces.dart';
import 'promo_code.dart';
import 'promotions.dart';

/// The Offers tab: the best offer as a featured card, the rest as cards, each with its code to copy.
class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    final promos = ref.watch(promotionsProvider);
    return Scaffold(
      appBar: AppBar(title: Semantics(header: true, child: Text('Offers', style: t.headline))),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(promotionsProvider.future).then((_) {}, onError: (_) {}),
        child: promos.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Message(
            icon: ApiFailure.from(e).isConnectivity ? LucideIcons.wifiOff : LucideIcons.circleAlert,
            danger: true,
            title: "Couldn't load offers",
            body: ApiFailure.from(e).isConnectivity ? "You're offline. Check your connection and try again." : 'Please try again in a moment.',
            action: IdButton.tonal(label: 'Try again', icon: LucideIcons.refreshCw, onPressed: () => ref.invalidate(promotionsProvider)),
          ),
          data: (list) => list.isEmpty
              ? const _Message(icon: LucideIcons.badgePercent, title: 'No offers right now', body: "New offers show up here, and we'll let you know when one starts.")
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(IdSpace.s4),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: IdSpace.s3),
                  itemBuilder: (context, i) => i == 0 ? _FeaturedPromo(list[i]) : _PromoCard(list[i]),
                ),
        ),
      ),
    );
  }
}

/// The first offer, on the offer colour with bubbles.
class _FeaturedPromo extends StatelessWidget {
  const _FeaturedPromo(this.promo);
  final PromotionDto promo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final terms = promoTerms(promo, withLimit: true, withValidity: true);
    // A one-time offer is a welcome offer.
    final label = promo.perCustomerLimit == 1 ? 'New here' : promoBadge(promo);

    return Semantics(
      container: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(IdRadius.lg),
        child: Container(
          color: c.offerSoft,
          padding: const EdgeInsets.all(IdSpace.s5),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(right: -44, top: -44, child: Bubble(110)),
              const Positioned(right: 24, bottom: -16, child: Bubble(44)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OfferChip(label),
                  const SizedBox(height: IdSpace.s3),
                  // Leaves room on the right so the bubbles never sit under the words.
                  Padding(
                    padding: const EdgeInsets.only(right: 56),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text(promo.title, style: t.headline)),
                        if (promo.description != null) ...[
                          const SizedBox(height: IdSpace.s1),
                          Text(promo.description!, style: t.bodyLg),
                        ],
                        const SizedBox(height: IdSpace.s1),
                        Text(terms, style: t.body.copyWith(color: c.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: IdSpace.s4),
                  PromoCodeChip(promo.code, onTap: () => copyPromoCode(context, promo.code)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard(this.promo);
  final PromotionDto promo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      container: true,
      child: IdCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OfferChip(promoBadge(promo)),
            const SizedBox(height: IdSpace.s2),
            Semantics(header: true, child: Text(promo.title, style: t.title)),
            if (promo.description != null) ...[
              const SizedBox(height: IdSpace.s1),
              Text(promo.description!, style: t.body),
            ],
            const SizedBox(height: IdSpace.s1),
            Text(promoTerms(promo, withLimit: true, withValidity: true), style: t.body.copyWith(color: c.textMuted)),
            const SizedBox(height: IdSpace.s3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PromoCodeChip(promo.code),
                IdButton.text(label: 'Copy code', onPressed: () => copyPromoCode(context, promo.code)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferChip extends StatelessWidget {
  const _OfferChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.offer, borderRadius: BorderRadius.circular(IdRadius.full)),
      child: Text(label, style: context.text.label.copyWith(color: c.onOffer, fontWeight: FontWeight.w700)),
    );
  }
}

/// The empty and error states: a soft circle with an icon and a bubble, a title, a line, and maybe one action.
class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body, this.action, this.danger = false});

  final IconData icon;
  final String title;
  final String body;
  final IdButton? action;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    // Always scrollable, so pull to refresh works on an empty or failed screen.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(IdSpace.s6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 132,
                      height: 132,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(color: danger ? c.dangerSoft : c.offerSoft, shape: BoxShape.circle),
                            child: ExcludeSemantics(child: Icon(icon, size: 52, color: danger ? c.danger : c.text)),
                          ),
                          if (!danger) const Positioned(right: 0, top: 6, child: Bubble(22)),
                        ],
                      ),
                    ),
                    const SizedBox(height: IdSpace.s4),
                    Semantics(header: true, child: Text(title, style: t.titleLg, textAlign: TextAlign.center)),
                    const SizedBox(height: IdSpace.s2),
                    Text(body, style: t.bodyLg.copyWith(color: c.textMuted), textAlign: TextAlign.center),
                    if (action != null) ...[const SizedBox(height: IdSpace.s5), action!],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
