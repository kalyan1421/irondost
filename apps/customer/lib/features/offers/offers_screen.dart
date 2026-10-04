import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/state_view.dart';
import 'promo_code.dart';
import 'promotions.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promos = ref.watch(promotionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Offers')),
      body: RefreshIndicator(
        onRefresh: () => ref
            .refresh(promotionsProvider.future)
            .then((_) {}, onError: (_) {}),
        child: promos.when(
          loading: () => Semantics(
            label: 'Loading offers',
            child: ListView(
              padding: const EdgeInsets.all(IdSpace.s5),
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: IdSpace.s4),
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64,
                            height: 22,
                            color: context.colors.surfaceSoft,
                          ),
                          const SizedBox(height: IdSpace.s3),
                          FractionallySizedBox(
                            widthFactor: .7,
                            child: Container(
                              height: 20,
                              color: context.colors.surfaceSoft,
                            ),
                          ),
                          const SizedBox(height: IdSpace.s2),
                          FractionallySizedBox(
                            widthFactor: .9,
                            child: Container(
                              height: 14,
                              color: context.colors.surfaceSoft,
                            ),
                          ),
                          const SizedBox(height: IdSpace.s3),
                          Container(
                            width: 104,
                            height: IdSize.touchTarget,
                            color: context.colors.surfaceSoft,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          error: (e, _) => ListStateView(
            icon: ApiFailure.from(e).isConnectivity
                ? LucideIcons.wifiOff
                : LucideIcons.circleAlert,
            tone: StateTone.danger,
            announce: true,
            title: 'Couldn’t load offers',
            body: ApiFailure.from(e).isConnectivity
                ? 'Check your connection and try again.'
                : 'Please try again in a moment.',
            action: IdButton(
              label: 'Try again',
              onPressed: () => ref.invalidate(promotionsProvider),
            ),
          ),
          data: (list) => list.isEmpty
              ? const ListStateView(
                  icon: LucideIcons.badgePercent,
                  title: 'No offers right now',
                  body: 'Available offers will appear here. Pull down to check again.',
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(IdSpace.s5),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) => _PromoRow(list[i]),
                ),
        ),
      ),
    );
  }
}

class _PromoRow extends StatelessWidget {
  const _PromoRow(this.promo);
  final PromotionDto promo;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: IdSpace.s4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: IdSpace.s2,
            vertical: IdSpace.s1,
          ),
          decoration: BoxDecoration(
            color: context.colors.offer,
            borderRadius: BorderRadius.circular(IdRadius.sm),
          ),
          child: Text(
            promoBadge(promo),
            style: context.text.labelSm.copyWith(color: context.colors.onOffer),
          ),
        ),
        const SizedBox(height: IdSpace.s3),
        Semantics(
          header: true,
          child: Text(promo.title, style: context.text.titleLg),
        ),
        if (promo.description?.isNotEmpty ?? false) ...[
          const SizedBox(height: IdSpace.s1),
          Text(promo.description!, style: context.text.body),
        ],
        const SizedBox(height: IdSpace.s2),
        Text(
          promoTerms(promo, withLimit: true, withValidity: true),
          style: context.text.caption.copyWith(color: context.colors.textMuted),
        ),
        const SizedBox(height: IdSpace.s3),
        PromoCodeChip(
          promo.code,
          onTap: () => copyPromoCode(context, promo.code),
        ),
      ],
    ),
  );
}
