import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/money.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/status_chip.dart';
import '../../design/widgets/surfaces.dart';

final activeOrdersProvider = FutureProvider<OrderPageDto>(
  (ref) => ref.watch(apiProvider).orders.ordersControllerList(scope: Scope.active),
);

/// Active orders. Order details, tracking and past orders come with the orders build.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final orders = ref.watch(activeOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Orders', style: t.headline)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(activeOrdersProvider.future).catchError((_) => const OrderPageDto(items: [], page: 1, pageSize: 20, total: 0)),
        child: orders.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Message(
            icon: LucideIcons.circleAlert,
            title: "Couldn't load your orders",
            body: ApiFailure.from(e).isConnectivity ? "You're offline. Check your connection." : 'Please try again.',
            action: IdButton.tonal(label: 'Try again', onPressed: () => ref.invalidate(activeOrdersProvider)),
          ),
          data: (page) => page.items.isEmpty
              ? _Message(
                  image: true,
                  title: 'No orders yet',
                  body: "Book a pickup and we'll collect your clothes.",
                  action: IdButton(label: 'Book a pickup', onPressed: () => context.go(Routes.home)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(IdSpace.s4),
                  itemCount: page.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: IdSpace.s3),
                  itemBuilder: (_, i) {
                    final o = page.items[i];
                    return IdCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(o.orderNumber, style: t.orderId)),
                              StatusChip(o.status),
                            ],
                          ),
                          const SizedBox(height: IdSpace.s2),
                          Text(
                            'Pickup ${_date(o.pickupDate)}, ${o.pickupSlotLabel} · Delivery ${_date(o.deliveryDate)}',
                            style: t.body.copyWith(color: c.textMuted),
                          ),
                          const SizedBox(height: IdSpace.s3),
                          Text(rupees(o.totalPaise), style: t.titleLg),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  static String _date(String isoDate) => DateFormat('EEE d MMM').format(DateTime.parse(isoDate));
}

class _Message extends StatelessWidget {
  const _Message({this.icon, this.image = false, required this.title, required this.body, required this.action});

  final IconData? icon;
  final bool image;
  final String title;
  final String body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return ListView(
      padding: const EdgeInsets.all(IdSpace.s8),
      children: [
        const SizedBox(height: IdSpace.s12),
        if (image)
          Image.asset('assets/brand/irondost-mark.png', height: 96, excludeFromSemantics: true)
        else
          Icon(icon, size: 52, color: c.danger),
        const SizedBox(height: IdSpace.s4),
        Text(title, style: t.titleLg, textAlign: TextAlign.center),
        const SizedBox(height: IdSpace.s2),
        Text(body, style: t.body.copyWith(color: c.textMuted), textAlign: TextAlign.center),
        const SizedBox(height: IdSpace.s5),
        Center(child: action),
      ],
    );
  }
}
