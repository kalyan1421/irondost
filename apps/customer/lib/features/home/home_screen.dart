import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/money.dart';
import '../../core/order_status.dart';
import '../../core/order_text.dart';
import '../../core/slots.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/screen_backdrop.dart';
import '../../design/widgets/service_art.dart';
import '../addresses/addresses_controller.dart';
import '../addresses/addresses_screen.dart';
import '../area_interest/tell_me_card.dart';
import '../catalogue/catalogue.dart';
import '../catalogue/booking_entry.dart';
import '../catalogue/laundry.dart';
import '../notifications/notifications.dart';
import '../offers/promo_code.dart';
import '../offers/promotions.dart';
import '../orders/order_detail_screen.dart' show bookAgain;
import '../orders/orders_list.dart';
import 'banners.dart';
import 'how_it_works.dart';
import 'offer_banners.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final addresses = ref.watch(addressesProvider);
    final address = ref.watch(selectedAddressProvider);
    return ScreenBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          toolbarHeight: 64,
          leadingWidth: 46 + IdSpace.s5 + IdSpace.s3,
          leading: const Padding(
            padding: EdgeInsets.only(left: IdSpace.s5),
            child: Center(child: _BrandAvatar()),
          ),
          titleSpacing: IdSpace.s3,
          actions: [
            Consumer(
              builder: (context, ref, _) {
                final unread = ref.watch(unreadCountProvider);
                return IconButton(
                  tooltip: unread > 0
                      ? 'Notifications, $unread unread'
                      : 'Notifications',
                  onPressed: () => context.push(Routes.notifications),
                  style: IconButton.styleFrom(
                    backgroundColor: c.surface,
                    fixedSize: const Size(46, 46),
                    elevation: 3,
                    shadowColor: c.royal.withValues(alpha: 0.3),
                  ),
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    smallSize: 8,
                    backgroundColor: c.danger,
                    child: const Icon(LucideIcons.bell),
                  ),
                );
              },
            ),
            const SizedBox(width: IdSpace.s2),
          ],
          title: Semantics(
            button: true,
            label: 'Pickup address ${address?.label ?? ''}. Tap to change.',
            excludeSemantics: true,
            child: InkWell(
              onTap: addresses.hasValue
                  ? () => showAddressPicker(context)
                  : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: IdSize.touchTarget,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup and delivery',
                      style: t.caption.copyWith(color: c.textMuted),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address == null
                                ? 'Add an address'
                                : [
                                    address.label,
                                    if (_area(address) != null) _area(address)!,
                                  ].join(' · '),
                            style: t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: IdSpace.s1),
                        Icon(
                          LucideIcons.chevronDown,
                          size: IdSize.iconSm,
                          color: c.text,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(catalogProvider);
            ref.invalidate(promotionsProvider);
            ref.invalidate(bannersProvider);
            ref.invalidate(ordersListProvider(Scope.active));
            ref.invalidate(ordersListProvider(Scope.past));
            await ref
                .read(catalogProvider.future)
                .catchError((_) => <CatalogCategoryDto>[]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              IdSpace.s5,
              IdSpace.s6,
              IdSpace.s5,
              IdSpace.s8,
            ),
            children: [
              if (address != null && !address.serviceable) ...[
                _OutOfArea(address),
                const SizedBox(height: IdSpace.s6),
              ],
              const _SearchPill(),
              const SizedBox(height: IdSpace.s5),
              const _PromoBanner(),
              const SizedBox(height: _sectionGap),
              const _SectionTitle('Everything for your clothes'),
              const SizedBox(height: _innerGap),
              const _ServiceTiles(),
              const _ActiveOrder(),
              const _RepeatLast(),
              const SizedBox(height: _sectionGap),
              const OfferBanners(),
              const _PopularPrices(),
              const SizedBox(height: _sectionGap),
              const _DoorstepBanner(),
              const SizedBox(height: _sectionGap),
              const _HowItWorksCard(),
              const SizedBox(height: _sectionGap),
              const _TagLine(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Space between Home sections: clear breaks, so each block reads on its own.
const double _sectionGap = 32;

/// Space between a section heading and its content, and between cards in one group.
const double _innerGap = 12;

String? _area(AddressDto a) => a.area ?? a.street;

class _OutOfArea extends StatelessWidget {
  const _OutOfArea(this.address);
  final AddressDto address;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'We’re not in ${address.area ?? address.city} yet',
        style: context.text.title.copyWith(color: context.colors.warning),
      ),
      const SizedBox(height: IdSpace.s1),
      Text(
        'Choose another address to book a pickup.',
        style: context.text.body,
      ),
      IdButton.text(
        label: 'Change address',
        onPressed: () => showAddressPicker(context),
      ),
      const SizedBox(height: IdSpace.s2),
      TellMeWhenHere(
        addressId: address.id,
        place: address.area ?? address.city,
      ),
    ],
  );
}

class _ActiveOrder extends ConsumerWidget {
  const _ActiveOrder();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersListProvider(Scope.active));
    final order = orders.value?.items.firstOrNull;
    if (order == null) {
      if (orders.hasError) {
        return Padding(
          padding: const EdgeInsets.only(bottom: IdSpace.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Couldn’t load active orders.',
                style: context.text.body.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
              IdButton.text(
                label: 'Try again',
                onPressed: () =>
                    ref.invalidate(ordersListProvider(Scope.active)),
              ),
            ],
          ),
        );
      }
      if (orders.isLoading) {
        return Padding(
          padding: const EdgeInsets.only(bottom: IdSpace.s6),
          child: Semantics(
            label: 'Loading active orders',
            child: Container(height: 64, color: context.colors.surfaceSoft),
          ),
        );
      }
      return const SizedBox.shrink();
    }
    final missed = deliveryEstimateMissed(order);
    final waitingForPickup =
        order.status == OrderStatus.pending ||
        order.status == OrderStatus.pickupAssigned;
    final total = orders.value?.total ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: _innerGap),
      child: _SoftCard(
        color: missed ? context.colors.warningSoft : context.colors.surface,
        padding: const EdgeInsets.fromLTRB(
          IdSpace.s4,
          IdSpace.s3,
          IdSpace.s2,
          IdSpace.s3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9F4FC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    LucideIcons.truck,
                    size: 22,
                    color: context.colors.ocean,
                  ),
                ),
                const SizedBox(width: IdSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.status.customerLabel,
                        style: context.text.title.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        keepWindowTogether(
                          '${waitingForPickup
                              ? 'Pickup'
                              : missed
                              ? 'Delivery estimate missed'
                              : 'Delivery'} · ${dayLong(waitingForPickup ? order.pickupDate : order.deliveryDate)}, ${windowFromLabel(waitingForPickup ? order.pickupSlotLabel : order.deliverySlotLabel)}',
                        ),
                        style: context.text.caption.copyWith(
                          color: context.colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Track order ${order.orderNumber}',
                  excludeSemantics: true,
                  button: true,
                  child: TextButton(
                    onPressed: () =>
                        context.push(Routes.order(order.id), extra: order),
                    child: const Text('Track'),
                  ),
                ),
              ],
            ),
            if (total > 1)
              Align(
                alignment: Alignment.centerLeft,
                child: IdButton.text(
                  label: 'View all $total active orders',
                  onPressed: () => context.go(Routes.orders),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RepeatLast extends ConsumerWidget {
  const _RepeatLast();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(ordersListProvider(Scope.active)).value;
    if (active == null || active.items.isNotEmpty) {
      return const SizedBox.shrink();
    }
    final past =
        ref.watch(ordersListProvider(Scope.past)).value?.items ?? const [];
    final last = past
        .where((o) => o.status == OrderStatus.delivered)
        .firstOrNull;
    if (last == null) return const SizedBox.shrink();
    // The same items bookAgain would put in the basket: those still in the price list.
    final pieces = last.items
        .where((i) => i.catalogItemId != null)
        .fold<num>(0, (a, i) => a + i.quantity)
        .toInt();
    if (pieces == 0) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: IdButton.text(
        label: 'Repeat last order · $pieces ${pieces == 1 ? 'item' : 'items'}',
        icon: LucideIcons.repeat,
        onPressed: () => bookAgain(context, ref, last),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------------------------
// Home sections

/// A white rounded card with a soft shadow: the surface used across the tab screens.
class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(IdSpace.s4),
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: c.royal.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Semantics(
          header: true,
          child: Text(
            text,
            style: context.text.titleLg.copyWith(
              color: context.colors.textMuted,
            ),
          ),
        ),
      ),
      if (trailing != null) Flexible(child: trailing!),
    ],
  );
}

/// "What needs freshening today?": opens item search. A slowly turning sky, royal and sun ring runs around it.
class _SearchPill extends ConsumerStatefulWidget {
  const _SearchPill();

  @override
  ConsumerState<_SearchPill> createState() => _SearchPillState();
}

class _SearchPillState extends ConsumerState<_SearchPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  /// Widget tests wait for the screen to settle, which a ring that never stops would prevent.
  static final _underTest = Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect "Reduce motion": the ring stays still.
    final still = _underTest || MediaQuery.disableAnimationsOf(context);
    if (still) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const radius = 22.0;
    const ring = 3.0;
    return Semantics(
      button: true,
      label: 'Search items and services',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: c.royal.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _spin,
          builder: (context, child) => DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: SweepGradient(
                colors: [c.sky, c.royal, c.sun, c.sky],
                stops: const [0, 0.4, 0.7, 1],
                transform: GradientRotation(_spin.value * 2 * math.pi),
              ),
            ),
            child: child,
          ),
          child: Padding(
            padding: const EdgeInsets.all(ring),
            child: Material(
              color: c.surface,
              borderRadius: BorderRadius.circular(radius - ring),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => startBooking(context, ref, search: true),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 54),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: IdSpace.s4),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.search,
                          size: IdSize.iconMd,
                          color: c.text,
                        ),
                        const SizedBox(width: IdSpace.s3),
                        Expanded(
                          child: Text(
                            'What needs freshening today?',
                            style: context.text.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The running offer on a deep brand blue panel: the shirt price big on the left, the offer and its code on the right.
/// Hidden when there is no offer running.
class _PromoBanner extends ConsumerWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promo = ref.watch(promotionsProvider).value?.firstOrNull;
    if (promo == null) return const SizedBox.shrink();
    final categories =
        ref.watch(servicesProvider).value ?? const <CatalogCategoryDto>[];
    final laundryShirt = _shirtIn(laundryCategoryOf(categories));
    final shirt = laundryShirt ?? _ironingShirt(categories);
    final priceLabel = laundryShirt != null ? 'washed & ironed' : 'per shirt';
    final c = context.colors;
    final t = context.text;
    const white = Colors.white;
    return Semantics(
      container: true,
      label:
          '${promo.title}. ${promoTerms(promo)}. Code ${promo.code}${shirt == null ? '' : '. Shirt ${rupees(shirt.effectivePricePaise)}'}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B49C2), Color(0xFF15358F)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF15358F).withValues(alpha: 0.28),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: white.withValues(alpha: 0.85),
                width: 1.5,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 136),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  IdSpace.s4,
                  IdSpace.s3,
                  IdSpace.s3,
                  IdSpace.s3,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (shirt != null)
                        Flexible(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.only(right: IdSpace.s3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '${rupees(shirt.effectivePricePaise)}*',
                                        style: t.display.copyWith(
                                          color: c.sun,
                                          fontSize: 50,
                                          height: 1.05,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 28),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          priceLabel,
                                          style: t.titleLg.copyWith(
                                            color: c.sun,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const ServiceArtImage(
                                      ServiceArt.ironing,
                                      size: 36,
                                    ),
                                    const SizedBox(width: IdSpace.s2),
                                    Flexible(
                                      child: Text(
                                        'just for you',
                                        style: t.label.copyWith(
                                          color: white,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  promo.title,
                                  textAlign: TextAlign.end,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.title.copyWith(
                                    color: white,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: IdSpace.s2),
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () =>
                                      copyPromoCode(context, promo.code),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: IdSize.touchTarget,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'USE\nCODE',
                                          textAlign: TextAlign.end,
                                          style: t.labelSm.copyWith(
                                            color: white,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w800,
                                            height: 1,
                                          ),
                                        ),
                                        const SizedBox(width: IdSpace.s2),
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: c.sun,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x40000000),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              promo.code,
                                              style: t.title.copyWith(
                                                color: c.ink,
                                                fontStyle: FontStyle.italic,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    '*T&C apply',
                                    style: t.caption.copyWith(color: white),
                                  ),
                                ),
                                const SizedBox(width: IdSpace.s2),
                                const Icon(
                                  LucideIcons.mapPin,
                                  size: IdSize.iconMd,
                                  color: white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The category slug whose name, slug or items mention [key]; null when the catalogue has nothing like it.
String? _serviceFor(List<CatalogCategoryDto> categories, String key) {
  for (final c in categories) {
    if ('${c.slug} ${c.name}'.toLowerCase().contains(key)) return c.slug;
  }
  for (final c in categories) {
    if (c.items.any((i) => i.name.toLowerCase().contains(key))) return c.slug;
  }
  return null;
}

/// The four service tiles: Laundry, Saree, Ironing and Carpets, each opening that service's price list.
class _ServiceTiles extends ConsumerWidget {
  const _ServiceTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories =
        ref.watch(servicesProvider).value ?? const <CatalogCategoryDto>[];
    final hasOffer = ref.watch(promotionsProvider).value?.isNotEmpty ?? false;
    final laundry = laundryCategoryOf(categories);
    final laundryShirt = _shirtIn(laundry);
    final shirt = _ironingShirt(categories);

    void open(String key) =>
        startBooking(context, ref, service: _serviceFor(categories, key));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Laundry, the main service: the biggest tile, first.
              _Tile(
                art: ServiceArt.laundry,
                kicker: laundryShirt == null
                    ? 'Wash & iron, wash & fold'
                    : '${rupees(laundryShirt.effectivePricePaise)} a piece',
                title: 'Laundry',
                badge: hasOffer ? 'Offers' : 'Own machines',
                kickerBelow: true,
                minHeight: 186,
                artSize: 100,
                onTap: () => startBooking(
                  context,
                  ref,
                  service: laundry?.slug ?? _serviceFor(categories, 'wash'),
                ),
              ),
              const SizedBox(height: _innerGap),
              _Tile(
                art: ServiceArt.carpets,
                kicker: 'Deep clean',
                title: 'Carpets',
                minHeight: 112,
                artSize: 96,
                onTap: () => open('carpet'),
              ),
            ],
          ),
        ),
        const SizedBox(width: _innerGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Tile(
                art: ServiceArt.ironing,
                kicker: shirt == null
                    ? 'Pressed\nand neat'
                    : 'Pressed\nshirt ${rupees(shirt.effectivePricePaise)}',
                title: 'Ironing',
                minHeight: 118,
                artSize: 96,
                onTap: () => open('iron'),
              ),
              const SizedBox(height: _innerGap),
              _Tile(
                art: ServiceArt.saree,
                kicker: 'Silk, cotton\nand party wear',
                title: 'Saree',
                minHeight: 180,
                artSize: 120,
                onTap: () => open('saree'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One Home service tile: what it is at the top left, and a 3D picture that breaks out of the card's bottom-right corner.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.art,
    required this.kicker,
    required this.title,
    required this.minHeight,
    required this.artSize,
    required this.onTap,
    this.badge,
    this.kickerBelow = false,
  });

  /// How far the picture reaches past the card's right and bottom edges. Kept under the gap between cards.
  static const double _bleed = 10;

  final ServiceArt art;
  final String kicker;
  final String title;
  final String? badge;
  final double minHeight;
  final double artSize;
  final VoidCallback onTap;

  /// The short line goes under the title instead of above it (Ironing: "Shirt at ₹15").
  final bool kickerBelow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final radius = BorderRadius.circular(24);
    final text = Padding(
      padding: const EdgeInsets.all(IdSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.badgePercent,
                    size: IdSize.iconSm,
                    color: c.primary,
                  ),
                  const SizedBox(width: IdSpace.s1),
                  Flexible(
                    child: Text(
                      badge!,
                      style: t.labelSm.copyWith(
                        color: c.onPrimarySoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: IdSpace.s2),
          ],
          if (!kickerBelow) ...[
            Text(
              kicker,
              style: t.body.copyWith(color: c.textMuted, height: 1.2),
            ),
            const SizedBox(height: IdSpace.s1),
          ],
          Text(title, style: t.titleLg),
          if (kickerBelow) ...[
            const SizedBox(height: 2),
            Text(kicker, style: t.caption.copyWith(color: c.textMuted)),
          ],
        ],
      ),
    );
    return Semantics(
      button: true,
      label:
          '$title. ${kicker.replaceAll('\n', ' ')}${badge == null ? '' : '. $badge'}',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.passthrough,
        children: [
          // The card: its own size comes from the text, at least minHeight.
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: c.royal.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: c.surface,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Opacity(opacity: 0, child: text),
                ),
              ),
            ),
          ),
          // The picture breaks out of the corner; taps fall through to the card.
          Positioned(
            right: -_bleed,
            bottom: -_bleed,
            child: IgnorePointer(child: _TileArt(art, size: artSize)),
          ),
          // The words sit above the picture so they always read.
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: IgnorePointer(child: text),
          ),
        ],
      ),
    );
  }
}

/// Up to four items to show prices for: a shirt, trousers, a saree and a suit when the price list has them.
List<CatalogItemDto> _popularItems(List<CatalogCategoryDto> categories) {
  // Laundry leads: its items are picked first, then the rest of the price list.
  final ordered = [
    ...categories.where(isLaundry),
    ...categories.where((c) => !isLaundry(c)),
  ];
  final all = [for (final c in ordered) ...c.items];
  final picked = <CatalogItemDto>[];
  for (final key in const ['shirt', 'trouser', 'bedsheet', 'saree']) {
    final match = all
        .where((i) => i.name.toLowerCase().contains(key) && !picked.contains(i))
        .firstOrNull;
    if (match != null) picked.add(match);
  }
  for (final i in all) {
    if (picked.length >= 4) break;
    if (!picked.contains(i)) picked.add(i);
  }
  return picked.take(4).toList();
}

/// The shirt in [category], or null.
CatalogItemDto? _shirtIn(CatalogCategoryDto? category) => category?.items
    .where((i) => i.name.toLowerCase().contains('shirt'))
    .firstOrNull;

/// The cheapest shirt outside laundry (ironing), or null.
CatalogItemDto? _ironingShirt(List<CatalogCategoryDto> categories) {
  final shirts = [
    for (final c in categories.where((c) => !isLaundry(c)))
      ...c.items.where((i) => i.name.toLowerCase().contains('shirt')),
  ]..sort((a, b) => a.effectivePricePaise.compareTo(b.effectivePricePaise));
  return shirts.firstOrNull;
}

class _PopularPrices extends ConsumerWidget {
  const _PopularPrices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories =
        ref.watch(servicesProvider).value ?? const <CatalogCategoryDto>[];
    final items = _popularItems(categories);
    final serviceOf = {
      for (final c in categories)
        for (final i in c.items) i.id: isLaundry(c) ? 'Laundry' : c.name,
    };
    if (items.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          'Popular prices',
          trailing: Semantics(
            button: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => startBooking(context, ref),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: IdSize.touchTarget,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Full rate card',
                        style: t.body.copyWith(
                          color: c.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: IdSize.iconSm + 2,
                      color: c.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: IdSpace.s1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (n, item) in items.indexed) ...[
              if (n > 0) const SizedBox(width: IdSpace.s2),
              Expanded(
                child: Semantics(
                  container: true,
                  label:
                      '${item.name}, ${rupees(item.effectivePricePaise)}, ${serviceOf[item.id] ?? ''}',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      _SoftCard(
                        padding: const EdgeInsets.symmetric(
                          vertical: IdSpace.s3,
                        ),
                        child: Center(
                          child: ServiceArtImage(
                            ServiceArt.match(item.name),
                            size: 52,
                          ),
                        ),
                      ),
                      const SizedBox(height: IdSpace.s2),
                      Text(
                        item.name,
                        style: t.labelSm.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: rupees(item.effectivePricePaise)),
                            if (item.offerPricePaise != null &&
                                item.offerPricePaise! < item.pricePaise)
                              TextSpan(
                                text: ' ${rupees(item.pricePaise)}',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        style: t.caption.copyWith(color: c.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      if (serviceOf[item.id] case final service?)
                        Text(
                          service,
                          style: t.caption.copyWith(
                            color: service == 'Laundry'
                                ? c.primary
                                : c.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// "Doorstep pick-ups": a short promise with the pickup bag. Tapping it starts a booking.
class _DoorstepBanner extends ConsumerWidget {
  const _DoorstepBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final shape = BorderRadius.circular(22);
    return Semantics(
      button: true,
      label: 'Book a pickup. Doorstep laundry, the price is shown first.',
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFF15358F),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: shape,
          side: BorderSide(color: c.mist, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => startBooking(context, ref),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.all(IdSpace.s4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DOORSTEP LAUNDRY',
                          style: t.titleLg.copyWith(
                            color: c.sun,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: IdSpace.s1),
                        Text(
                          '@ price shown first!',
                          style: t.title.copyWith(
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const ServiceArtImage(ServiceArt.pickupBag, size: 76),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three steps, with the longer explanation one tap away.
class _HowItWorksCard extends ConsumerWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    Widget step(IconData icon, String label, Color bg) => Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: IdSize.iconMd, color: c.text),
          ),
          const SizedBox(height: IdSpace.s2),
          Text(
            label,
            style: t.labelSm.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      hint: 'Opens the full explanation',
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: () => showHowItWorks(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(IdSpace.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('How it works', style: t.titleLg)),
                    Icon(
                      LucideIcons.chevronRight,
                      size: IdSize.iconSm,
                      color: c.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: IdSpace.s4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    step(
                      LucideIcons.smartphone,
                      'Book in the app',
                      c.primarySoft,
                    ),
                    step(
                      LucideIcons.truck,
                      'We pick up at your door',
                      const Color(0xFFD9F4FC),
                    ),
                    step(
                      LucideIcons.house,
                      'Delivered back, fresh',
                      c.offerSoft,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TagLine extends StatelessWidget {
  const _TagLine();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final art = _footerArt.replaceAll(
      '#C9D8F2',
      '#${(Theme.of(context).brightness == Brightness.dark ? c.border : const Color(0xFFC9D8F2)).toARGB32().toRadixString(16).substring(2)}',
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 190),
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: SvgPicture.string(art, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 40, bottom: IdSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '#FreshAtYourDoor',
                      style: t.headline.copyWith(
                        fontSize: 34,
                        height: 1.05,
                        color: c.royal.withValues(alpha: 0.35),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: IdSpace.s3),
                Row(
                  children: [
                    Icon(
                      LucideIcons.house,
                      size: IdSize.iconSm,
                      color: c.primary,
                    ),
                    const SizedBox(width: IdSpace.s2),
                    Expanded(
                      child: Text(
                        'Made for Hyderabad homes',
                        style: t.body.copyWith(color: c.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: IdSpace.s1),
                Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: IdSize.iconSm,
                      color: c.primary,
                    ),
                    const SizedBox(width: IdSpace.s2),
                    Expanded(
                      child: Text(
                        'Pickups around LB Nagar',
                        style: t.body.copyWith(color: c.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Faint line drawings behind the footer: a shirt, a washer, a bag and a delivery bike on a dashed route.
const _footerArt =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 390 190" fill="none" stroke="#C9D8F2" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">'
    '<path d="M0 170c60-26 120 18 190-8s130-10 200-28" stroke-dasharray="5 6"/>'
    '<path d="M18 20l-16 10 6 12 10-3v32h26V39l10 3 6-12-16-10a12 12 0 0 1-26 0z"/>'
    '<rect x="296" y="14" width="54" height="64" rx="10"/><circle cx="323" cy="46" r="18"/><path d="M309 50c6-6 9 5 14 0s9 5 14 0"/>'
    '<path d="M250 60h40l-4-18c-2-7-7-9-15-9h-6c-8 0-13 4-13 11z"/>'
    '<circle cx="52" cy="150" r="11"/><circle cx="98" cy="150" r="11"/><path d="M52 150l14-26h20l10 26"/>'
    '<path d="M330 120h40v22h-40zM340 120v-10h20v10"/>'
    '</svg>';

/// The IronDost mark in a white circle: the Home header's leading avatar.
class _BrandAvatar extends StatelessWidget {
  const _BrandAvatar();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: Container(
        width: 46,
        height: 46,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: c.royal.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Image.asset('assets/brand/irondost-mark.png'),
      ),
    );
  }
}

/// The 3D render for a Home service tile, falling back to the flat [ServiceArt] picture when there is none.
class _TileArt extends StatelessWidget {
  const _TileArt(this.art, {required this.size});

  final ServiceArt art;
  final double size;

  static const _renders = {
    ServiceArt.laundry: 'assets/services/wash-and-iron-3d.png',
    ServiceArt.ironing: 'assets/services/ironing-3d.png',
    ServiceArt.saree: 'assets/services/saree-3d.png',
    ServiceArt.carpets: 'assets/services/carpets-3d.png',
  };

  @override
  Widget build(BuildContext context) {
    final render = _renders[art];
    if (render == null) return ServiceArtImage(art, size: size);
    return ExcludeSemantics(
      child: Image.asset(
        render,
        width: size,
        height: size,
        fit: BoxFit.contain,
        cacheWidth: (size * 3).round(),
        errorBuilder: (_, _, _) => ServiceArtImage(art, size: size),
      ),
    );
  }
}
