import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/order_card.dart';
import '../../design/widgets/surfaces.dart';
import 'orders_list.dart';
import 'pay_due.dart';

/// The Orders tab: active orders and past ones, newest first, a page at a time.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  Scope _scope = Scope.active;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final activeTotal = ref.watch(ordersListProvider(Scope.active).select((v) => v.value?.total ?? 0));

    return Scaffold(
      body: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: c.surface, border: Border(bottom: BorderSide(color: c.border))),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s2, IdSpace.s4, IdSpace.s3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text('Orders', style: t.headline)),
                    const SizedBox(height: IdSpace.s3),
                    SegmentedTabs(
                      label: 'Order filter',
                      options: [activeTotal > 0 ? 'Active ($activeTotal)' : 'Active', 'Past'],
                      selected: _scope == Scope.active ? 0 : 1,
                      onSelect: (i) => setState(() => _scope = i == 0 ? Scope.active : Scope.past),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _Orders(key: ValueKey(_scope), scope: _scope)),
        ],
      ),
    );
  }
}

class _Orders extends ConsumerStatefulWidget {
  const _Orders({super.key, required this.scope});
  final Scope scope;

  @override
  ConsumerState<_Orders> createState() => _OrdersState();
}

class _OrdersState extends ConsumerState<_Orders> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.extentAfter < 400) {
        ref.read(ordersListProvider(widget.scope).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final orders = ref.watch(ordersListProvider(scope));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ordersListProvider(scope));
        await ref.read(ordersListProvider(scope).future).then((_) {}, onError: (_) {});
      },
      child: orders.when(
        loading: () => const _Skeleton(),
        error: (e, _) => _Message(
          icon: ApiFailure.from(e).isConnectivity ? LucideIcons.wifiOff : LucideIcons.circleAlert,
          tone: _Tone.danger,
          title: "Couldn't load your orders",
          body: ApiFailure.from(e).isConnectivity ? "You're offline. Check your connection and try again." : 'Please try again in a moment.',
          action: IdButton.tonal(label: 'Try again', icon: LucideIcons.refreshCw, onPressed: () => ref.invalidate(ordersListProvider(scope))),
        ),
        data: (list) {
          if (list.items.isEmpty) {
            return scope == Scope.active
                ? _Message(
                    image: true,
                    title: 'No orders yet',
                    body: "Book a pickup and we'll collect your clothes.",
                    action: IdButton(label: 'Book a pickup', onPressed: () => context.go(Routes.home)),
                  )
                : const _Message(icon: LucideIcons.package, title: 'No past orders yet', body: 'Delivered and cancelled orders show up here.');
          }
          return ListView.separated(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s4, IdSpace.s4, IdSpace.s6),
            itemCount: list.items.length + (list.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: IdSpace.s3),
            itemBuilder: (_, i) {
              if (i == list.items.length) return _MoreFooter(list: list, onRetry: () => ref.read(ordersListProvider(scope).notifier).loadMore());
              final order = list.items[i];
              return OrderCard(
                key: ValueKey(order.id),
                order: order,
                onOpen: () => context.push(Routes.order(order.id), extra: order),
                onPay: () => showPayDueSheet(context, order),
              );
            },
          );
        },
      ),
    );
  }
}

class _MoreFooter extends StatelessWidget {
  const _MoreFooter({required this.list, required this.onRetry});
  final OrderList list;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (list.moreFailed) {
      return Center(
        child: IdButton.text(label: "Couldn't load more. Try again", icon: LucideIcons.refreshCw, onPressed: onRetry),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(IdSpace.s4),
      child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget block(double w, double h) => Container(width: w, height: h, decoration: BoxDecoration(color: c.surfaceSoft, borderRadius: BorderRadius.circular(IdRadius.sm)));
    return Semantics(
      label: 'Loading your orders',
      child: ExcludeSemantics(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(IdSpace.s4),
          children: [
            for (var i = 0; i < 3; i++) ...[
              IdCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [block(96, 16), block(72, 24)]),
                    const SizedBox(height: IdSpace.s3),
                    block(220, 14),
                    const SizedBox(height: IdSpace.s3),
                    SizedBox(width: double.infinity, child: block(double.infinity, 52)),
                    const SizedBox(height: IdSpace.s3),
                    block(80, 22),
                  ],
                ),
              ),
              const SizedBox(height: IdSpace.s3),
            ],
          ],
        ),
      ),
    );
  }
}

enum _Tone { neutral, danger }

/// A centred message that still scrolls (so pull-to-refresh works) with an optional action.
class _Message extends StatelessWidget {
  const _Message({this.icon, this.image = false, this.tone = _Tone.neutral, required this.title, required this.body, this.action});

  final IconData? icon;
  final bool image;
  final _Tone tone;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final danger = tone == _Tone.danger;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(IdSpace.s8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (image)
                    ExcludeSemantics(child: Image.asset('assets/brand/irondost-mark.png', height: 120))
                  else
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(color: danger ? c.dangerSoft : c.surfaceSoft, shape: BoxShape.circle),
                      child: Icon(icon, size: 44, color: danger ? c.danger : c.textMuted),
                    ),
                  const SizedBox(height: IdSpace.s4),
                  Semantics(header: true, liveRegion: true, child: Text(title, style: t.titleLg, textAlign: TextAlign.center)),
                  const SizedBox(height: IdSpace.s2),
                  Text(body, style: t.bodyLg.copyWith(color: c.textMuted), textAlign: TextAlign.center),
                  if (action != null) ...[const SizedBox(height: IdSpace.s4), action!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
