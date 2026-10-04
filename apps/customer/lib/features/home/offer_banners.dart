import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import 'banners.dart';
import '../catalogue/booking_entry.dart';

/// Manual paging keeps admin campaigns visible without distracting automatic motion.
class OfferBanners extends ConsumerWidget {
  const OfferBanners({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(homeOfferBannersProvider);
    if (banners.isEmpty) return const SizedBox.shrink();
    // New campaign order/content gets a fresh page controller, so the image,
    // title, position and link always refer to the same campaign after refresh.
    return _BannerCarousel(
      key: ValueKey(banners.map((b) => '${b.id}:${b.imageUrl}').join('|')),
      banners: banners,
    );
  }
}

class _BannerCarousel extends ConsumerStatefulWidget {
  const _BannerCarousel({super.key, required this.banners});
  final List<BannerDto> banners;
  @override
  ConsumerState<_BannerCarousel> createState() => _OfferBannersState();
}

class _OfferBannersState extends ConsumerState<_BannerCarousel> {
  final _pages = PageController();
  int _page = 0;
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _open(BannerDto banner) async {
    final link = banner.linkUrl?.trim();
    if (link == null || link.isEmpty) return;
    final route = bannerAppRoute(link);
    if (route != null) {
      final uri = Uri.parse(route);
      if (uri.path == Routes.book || uri.path == Routes.bookSearch) {
        startBooking(
          context,
          ref,
          service: uri.queryParameters['service'],
          search: uri.path == Routes.bookSearch,
        );
        return;
      }
      if ({
        Routes.home,
        Routes.orders,
        Routes.offers,
        Routes.account,
      }.contains(Uri.parse(route).path)) {
        context.go(route);
      } else {
        await context.push(route);
      }
      return;
    }
    final uri = Uri.tryParse(link);
    var opened = false;
    try {
      if (uri != null &&
          {'https', 'http'}.contains(uri.scheme) &&
          uri.host.isNotEmpty) {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Invalid or unavailable admin links leave the customer on Home.
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This offer link is unavailable. See Offers for current promotions.',
          ),
        ),
      );
    }
  }

  void _changePage(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    final page = _page.clamp(0, banners.length - 1);
    final current = banners[page];
    final linked = current.linkUrl?.trim().isNotEmpty ?? false;
    final title = current.title?.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: IdSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Offers', style: context.text.titleLg)),
              TextButton(
                onPressed: () => context.go(Routes.offers),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: IdSpace.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(IdRadius.lg),
            child: AspectRatio(
              aspectRatio: 2,
              child: PageView.builder(
                controller: _pages,
                itemCount: banners.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final banner = banners[i];
                  final canOpen = banner.linkUrl?.trim().isNotEmpty ?? false;
                  return Semantics(
                    container: true,
                    label:
                        '${banner.title?.trim().isNotEmpty == true ? banner.title : 'Offer'}${banners.length > 1 ? ', ${i + 1} of ${banners.length}' : ''}',
                    button: canOpen,
                    child: InkWell(
                      onTap: canOpen ? () => _open(banner) : null,
                      child: ExcludeSemantics(
                        child: _BannerImage(banner.imageUrl),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (title != null && title.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: IdSize.touchTarget),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title, style: context.text.body),
              ),
            ),
          if (linked)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _open(current),
                child: const Text('View offer'),
              ),
            ),
          if (banners.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Previous offer',
                  onPressed: page == 0 ? null : () => _changePage(page - 1),
                  icon: const Icon(LucideIcons.chevronLeft),
                ),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    '${page + 1} of ${banners.length}',
                    style: context.text.caption.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next offer',
                  onPressed: page == banners.length - 1
                      ? null
                      : () => _changePage(page + 1),
                  icon: const Icon(LucideIcons.chevronRight),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BannerImage extends ConsumerWidget {
  const _BannerImage(this.url);
  final String url;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = ColoredBox(
      color: context.colors.surfaceSoft,
      child: Center(
        child: Icon(
          LucideIcons.badgePercent,
          size: 32,
          color: context.colors.textMuted,
        ),
      ),
    );
    return Image(
      image: ref.watch(bannerImageProvider(url)),
      fit: BoxFit.contain,
      frameBuilder: (_, child, frame, synchronouslyLoaded) =>
          synchronouslyLoaded || frame != null ? child : fallback,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
