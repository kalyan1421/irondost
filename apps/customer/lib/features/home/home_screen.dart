import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../design/widgets/service_visual.dart';
import '../addresses/addresses_controller.dart';
import '../addresses/addresses_screen.dart';
import '../auth/session.dart';
import '../catalogue/catalogue.dart';
import '../catalogue/booking_entry.dart';
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
    final profile = switch (ref.watch(sessionProvider).value) {
      SignedIn(:final profile) => profile,
      _ => null,
    };
    final firstName = profile?.name?.trim().split(RegExp(r'\s+')).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: IdSpace.s5,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unread = ref.watch(unreadCountProvider);
              return IconButton(
                tooltip: unread > 0
                    ? 'Notifications, $unread unread'
                    : 'Notifications',
                onPressed: () => context.push(Routes.notifications),
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
            onTap: addresses.hasValue ? () => showAddressPicker(context) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: IdSize.touchTarget),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup from',
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
            Semantics(
              header: true,
              child: Text(
                firstName == null || firstName.isEmpty
                    ? 'Fresh clothes, made simple'
                    : 'Hello, $firstName',
                style: t.headline,
              ),
            ),
            const SizedBox(height: IdSpace.s2),
            Text(
              'Ironing, washing and dry cleaning.',
              style: t.body.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: IdSpace.s6),
            const _ActiveOrder(),
            IdButton(
              label: 'Book a pickup',
              expand: true,
              onPressed: () => startBooking(context, ref),
            ),
            const _RepeatLast(),
            const SizedBox(height: IdSpace.s6),
            const _Services(),
            const SizedBox(height: IdSpace.s6),
            const OfferBanners(),
            const _Offer(),
          ],
        ),
      ),
    );
  }
}

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
    return Padding(
      padding: const EdgeInsets.only(bottom: IdSpace.s6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: missed ? context.colors.warning : context.colors.primary,
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: IdSpace.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.status.customerLabel, style: context.text.titleLg),
              const SizedBox(height: IdSpace.s1),
              Text(
                '${waitingForPickup
                    ? 'Pickup'
                    : missed
                    ? 'Delivery estimate missed'
                    : 'Delivery'} · ${dayLong(waitingForPickup ? order.pickupDate : order.deliveryDate)}, ${windowFromLabel(waitingForPickup ? order.pickupSlotLabel : order.deliverySlotLabel)}',
                style: context.text.body,
              ),
              const SizedBox(height: IdSpace.s1),
              Text(
                '${order.orderNumber} · ${piecesLabel(order)}',
                style: context.text.caption.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
              IdButton.text(
                label: 'Track order',
                onPressed: () =>
                    context.push(Routes.order(order.id), extra: order),
              ),
              if ((orders.value?.total ?? 0) > 1)
                IdButton.text(
                  label: 'View all ${orders.value!.total} active orders',
                  onPressed: () => context.go(Routes.orders),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Repeat last order · 12 items": a way back to the same basket for a returning customer.
///
/// Only when nothing is in progress. With an active order, tracking it is the useful shortcut; and
/// past orders are then not loaded every time Home opens.
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

class _Services extends ConsumerWidget {
  const _Services();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(servicesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Services', style: context.text.titleLg),
        ),
        const SizedBox(height: IdSpace.s2),
        catalog.when(
          loading: () => Semantics(
            label: 'Loading services',
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: IdSpace.s2),
                    child: Container(
                      height: 64,
                      color: context.colors.surfaceSoft,
                    ),
                  ),
              ],
            ),
          ),
          error: (_, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Couldn’t load prices.', style: context.text.body),
              IdButton.text(
                label: 'Try again',
                onPressed: () => ref.invalidate(catalogProvider),
              ),
            ],
          ),
          data: (categories) => Column(
            children: [
              for (final cat in categories)
                Semantics(
                  button: true,
                  child: Material(
                    color: context.colors.surface,
                    child: InkWell(
                      onTap: () =>
                          startBooking(context, ref, service: cat.slug),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: context.colors.border),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: IdSpace.s4,
                        ),
                        child: Row(
                          children: [
                            ServiceVisual(category: cat),
                            const SizedBox(width: IdSpace.s3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cat.name, style: context.text.title),
                                  const SizedBox(height: IdSpace.s1),
                                  if (cat.items.isNotEmpty)
                                    Text(
                                      'From ${rupees(cat.items.map((i) => i.effectivePricePaise).reduce((a, b) => a < b ? a : b))}',
                                      style: context.text.caption.copyWith(
                                        color: context.colors.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              LucideIcons.chevronRight,
                              size: IdSize.iconSm,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: IdButton.text(
                  label: 'How it works',
                  icon: LucideIcons.info,
                  onPressed: () => showHowItWorks(context, ref),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Offer extends ConsumerWidget {
  const _Offer();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promo = ref.watch(promotionsProvider).value?.firstOrNull;
    if (promo == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      padding: const EdgeInsets.only(top: IdSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(promo.title, style: context.text.title),
          const SizedBox(height: IdSpace.s1),
          Text(
            promoTerms(promo),
            style: context.text.caption.copyWith(
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: IdSpace.s2),
          PromoCodeChip(
            promo.code,
            onTap: () => copyPromoCode(context, promo.code),
          ),
        ],
      ),
    );
  }
}
