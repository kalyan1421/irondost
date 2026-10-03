import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/money.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/surfaces.dart';
import '../addresses/addresses_controller.dart';
import '../addresses/addresses_screen.dart';
import '../catalogue/catalogue.dart';
import '../notifications/notifications.dart';
import '../offers/promotions.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final addresses = ref.watch(addressesProvider);
    final address = ref.watch(selectedAddressProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: IdSpace.s4,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unread = ref.watch(unreadCountProvider);
              return IconButton(
                tooltip: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
                onPressed: () => context.push(Routes.notifications),
                icon: Badge(isLabelVisible: unread > 0, smallSize: 8, backgroundColor: c.danger, child: const Icon(LucideIcons.bell)),
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
            borderRadius: BorderRadius.circular(IdRadius.sm),
            onTap: addresses.hasValue ? () => showAddressPicker(context) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: IdSize.touchTarget),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pickup from', style: t.caption.copyWith(color: c.textMuted)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          address == null ? 'Add an address' : [address.label, if (_area(address) != null) _area(address)!].join(' · '),
                          style: t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: IdSpace.s1),
                      Icon(LucideIcons.chevronDown, size: IdSize.iconSm, color: c.text),
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
          await ref.read(catalogProvider.future).catchError((_) => <CatalogCategoryDto>[]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s4, IdSpace.s4, IdSpace.s6),
          children: [
            if (address != null && !address.serviceable) ...[
              _OutOfArea(address),
              const SizedBox(height: IdSpace.s4),
            ],
            const _Hero(),
            const SizedBox(height: IdSpace.s6),
            const _Services(),
            const SizedBox(height: IdSpace.s6),
            const _Offer(),
          ],
        ),
      ),
    );
  }
}

/// "Banjara Hills" for the header: the neighbourhood, else the street.
String? _area(AddressDto a) => a.area ?? a.street;

class _OutOfArea extends StatelessWidget {
  const _OutOfArea(this.address);
  final AddressDto address;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(IdRadius.md)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.mapPinOff, size: IdSize.iconMd, color: c.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("We're not in ${address.area ?? address.city} yet", style: t.title),
                const SizedBox(height: 2),
                Text('Pick another address to book a pickup. We\'ll tell you when IronDost reaches here.', style: t.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the catalogue (on [service]'s tab, when given). Orders can only be picked up from an
/// address we serve, so for any other the customer is asked to choose one that is.
void startBooking(BuildContext context, WidgetRef ref, {String? service}) {
  final address = ref.read(selectedAddressProvider);
  if (address == null) {
    context.push(Routes.addressPin);
    return;
  }
  if (!address.serviceable) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text("We don't pick up from ${address.area ?? address.city} yet. Choose another address.")));
    showAddressPicker(context);
    return;
  }
  context.push(service == null ? Routes.book : Uri(path: Routes.book, queryParameters: {'service': service}).toString());
}

class _Hero extends ConsumerWidget {
  const _Hero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    return ClipRRect(
      borderRadius: BorderRadius.circular(IdRadius.xl),
      child: Container(
        color: c.royal,
        padding: const EdgeInsets.all(IdSpace.s5),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -56,
              bottom: -64,
              child: ExcludeSemantics(
                child: Container(
                  width: 184,
                  height: 184,
                  alignment: const Alignment(-0.2, -0.3),
                  decoration: BoxDecoration(color: c.illoFoam, shape: BoxShape.circle),
                  child: Image.asset('assets/brand/irondost-mark.png', width: 120),
                ),
              ),
            ),
            // Bubbles stay right of the 200dp text column.
            const Positioned(right: 64, top: 44, child: Bubble(14)),
            const Positioned(right: 4, top: -4, child: Bubble(40)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 200,
                  child: Semantics(
                    header: true,
                    child: Text('Fresh clothes, back at your door.', style: t.headline.copyWith(color: c.white)),
                  ),
                ),
                const SizedBox(height: IdSpace.s3),
                Text('Ironed and back in a day.', style: t.body.copyWith(color: c.white)),
                const SizedBox(height: IdSpace.s4),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: c.white, foregroundColor: c.royal),
                  onPressed: () => startBooking(context, ref),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(LucideIcons.chevronRight, size: IdSize.iconMd),
                  label: const Text('Book a pickup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Services extends ConsumerWidget {
  const _Services();

  static IconData _icon(String slug) => switch (slug) {
        'wash-and-iron' => LucideIcons.washingMachine,
        'dry-cleaning' => LucideIcons.sparkles,
        _ => LucideIcons.shirt,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final catalog = ref.watch(servicesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text('Services', style: t.titleLg)),
        const SizedBox(height: IdSpace.s3),
        catalog.when(
          loading: () => const _ServiceGrid(children: [_ServiceSkeleton(), _ServiceSkeleton(), _ServiceSkeleton()]),
          error: (e, _) => IdCard(
            child: Row(
              children: [
                Icon(LucideIcons.circleAlert, color: c.danger),
                const SizedBox(width: IdSpace.s3),
                Expanded(child: Text("Couldn't load prices.", style: t.body)),
                TextButton(onPressed: () => ref.invalidate(catalogProvider), child: const Text('Try again')),
              ],
            ),
          ),
          data: (categories) => _ServiceGrid(
            children: [
              for (final cat in categories)
                IdCard(
                  padding: const EdgeInsets.fromLTRB(IdSpace.s2, IdSpace.s4, IdSpace.s2, 14),
                  onTap: () => startBooking(context, ref, service: cat.slug),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(IdRadius.md)),
                        child: Icon(_icon(cat.slug), color: c.onPrimarySoft),
                      ),
                      const SizedBox(height: IdSpace.s2),
                      Text(cat.name, style: t.label, textAlign: TextAlign.center, maxLines: 2),
                      Text(
                        'from ${rupees(cat.items.map((i) => i.effectivePricePaise).reduce((a, b) => a < b ? a : b))}',
                        style: t.caption.copyWith(color: c.textMuted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          const gap = IdSpace.s3;
          final width = (box.maxWidth - gap * 2) / 3;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [for (final child in children) SizedBox(width: width, child: child)],
          );
        },
      );
}

class _ServiceSkeleton extends StatelessWidget {
  const _ServiceSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        height: 116,
        decoration: BoxDecoration(color: context.colors.surfaceSoft, borderRadius: BorderRadius.circular(IdRadius.lg)),
      );
}

class _Offer extends ConsumerWidget {
  const _Offer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promo = ref.watch(promotionsProvider).value?.firstOrNull;
    if (promo == null) return const SizedBox.shrink();
    final c = context.colors;
    final t = context.text;
    final terms = promoTerms(promo);

    return ClipRRect(
      borderRadius: BorderRadius.circular(IdRadius.lg),
      child: Container(
        color: c.offerSoft,
        padding: const EdgeInsets.all(IdSpace.s5),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(right: -50, top: -50, child: Bubble(110)),
            const Positioned(right: 24, top: 56, child: Bubble(22)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 240, child: Text(promo.title, style: t.titleLg)),
                if (terms.isNotEmpty) ...[
                  const SizedBox(height: IdSpace.s2),
                  Text(terms, style: t.body.copyWith(color: c.textMuted)),
                ],
                const SizedBox(height: IdSpace.s3),
                Semantics(
                  button: true,
                  label: 'Copy code ${promo.code}',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(IdRadius.sm),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: promo.code));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Code ${promo.code} copied')));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(IdRadius.sm),
                        border: Border.all(color: c.text, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(promo.code, style: t.orderId),
                          const SizedBox(width: 6),
                          Icon(LucideIcons.copy, size: IdSize.iconSm, color: c.text),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
