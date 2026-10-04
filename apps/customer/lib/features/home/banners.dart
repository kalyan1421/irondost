import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../data/api_client.dart';
import '../offers/promotions.dart';

/// Images, titles, optional links and ordering are managed by the existing admin Banners page.
final bannersProvider = FutureProvider<List<BannerDto>>((ref) async {
  final all = await ref.watch(apiProvider).banners.bannersControllerActive();
  return activeBanners(all);
});

/// Promotion images follow the existing server-controlled validity window.
/// Standalone admin banners remain available alongside scheduled campaigns.
final homeOfferBannersProvider = Provider<List<BannerDto>>((ref) {
  final campaigns = promotionBanners(
    ref.watch(promotionsProvider).value ?? const [],
  );
  final standalone = ref.watch(bannersProvider).value ?? const <BannerDto>[];
  final seen = <String>{};
  return [
    ...campaigns,
    ...standalone,
  ].where((banner) => seen.add(banner.imageUrl)).toList();
});

List<BannerDto> promotionBanners(List<PromotionDto> promotions) => [
  for (final promo in promotions)
    if (promo.isActive && (promo.imageUrl?.trim().isNotEmpty ?? false))
      BannerDto(
        id: 'promotion:${promo.id}',
        imageUrl: promo.imageUrl!.trim(),
        title:
            '${promo.title} · ${promoTerms(promo, withValidity: true, withLimit: true)}',
        linkUrl: Routes.offers,
        sortOrder: 0,
        isActive: true,
      ),
];

List<BannerDto> activeBanners(List<BannerDto> all) =>
    all.where((b) => b.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

/// Overridable for offline renders; production always loads the admin image URL.
final bannerImageProvider = Provider.family<ImageProvider, String>(
  (ref, url) => NetworkImage(url),
);

/// Supported customer destinations; promotional links never submit or pay for an order.
String? bannerAppRoute(String link) {
  final uri = Uri.tryParse(link.trim());
  if (uri == null) return null;
  String path;
  if (uri.scheme == 'irondost') {
    path =
        '/${[if (uri.host.isNotEmpty) uri.host, ...uri.pathSegments].join('/')}';
  } else if (!uri.hasScheme && !uri.hasAuthority && uri.path.startsWith('/')) {
    path = uri.path;
  } else {
    return null;
  }
  if (path.startsWith('/orders/')) {
    path = path.replaceFirst('/orders/', '/order/');
  }
  if ({
        Routes.home,
        Routes.offers,
        Routes.orders,
        Routes.account,
        Routes.help,
        Routes.book,
        Routes.bookSearch,
        Routes.basket,
        Routes.notifications,
        Routes.addresses,
        ...Routes.publicLegalRoutes,
      }.contains(path) ||
      RegExp(r'^/order/[^/]+$').hasMatch(path)) {
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }
  return null;
}
