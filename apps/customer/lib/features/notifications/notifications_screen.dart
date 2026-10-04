import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/slots.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/state_view.dart';
import '../../design/widgets/surfaces.dart';
import 'notifications.dart';

/// The inbox: what happened to the customer's orders and payments, newest first, grouped Today / Earlier.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.extentAfter < 400) {
        ref.read(notificationsProvider.notifier).loadMore();
      }
    });
    // Fresh each time it is opened: pushes arrive while the inbox is not on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(notificationsProvider);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _open(NotificationDto n) {
    ref.read(notificationsProvider.notifier).markRead(n.id);
    final orderId = notificationOrderId(n);
    if (orderId != null) {
      context.push(Routes.order(orderId));
    } else if (n.type.contains('offer') || n.type.contains('promo')) {
      context.go(Routes.offers);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsProvider);
    final list = async.value;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: Text('Notifications', style: context.text.titleLg),
        actions: [
          if ((list?.unread ?? 0) > 0)
            // With large text the label no longer fits beside the title, so it becomes an icon with the same name.
            if (MediaQuery.textScalerOf(context).scale(1) > 1.3)
              IconButton(
                tooltip: 'Mark all read',
                icon: const Icon(LucideIcons.checkCheck),
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).markAllRead(),
              )
            else
              TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).markAllRead(),
                child: const Text('Mark all read'),
              ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          await ref
              .read(notificationsProvider.future)
              .then((_) {}, onError: (_) {});
        },
        child: async.when(
          loading: () => list == null
              ? const _Skeleton()
              : _Body(list: list, controller: _scroll, onOpen: _open),
          error: (e, _) => list != null
              ? _Body(list: list, controller: _scroll, onOpen: _open)
              : ListStateView(
                  icon: ApiFailure.from(e).isConnectivity
                      ? LucideIcons.wifiOff
                      : LucideIcons.circleAlert,
                  tone: StateTone.danger,
                  announce: true,
                  title: "Couldn't load notifications",
                  body: ApiFailure.from(e).isConnectivity
                      ? "You're offline. Check your connection and try again."
                      : 'Please try again in a moment.',
                  action: IdButton.tonal(
                    label: 'Try again',
                    icon: LucideIcons.refreshCw,
                    onPressed: () => ref.invalidate(notificationsProvider),
                  ),
                ),
          data: (list) => list.items.isEmpty
              ? const ListStateView(
                  icon: LucideIcons.bell,
                  title: "You're all caught up",
                  body: 'Updates on your orders and payments will appear here.',
                )
              : _Body(list: list, controller: _scroll, onOpen: _open),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.list,
    required this.controller,
    required this.onOpen,
  });

  final NotificationList list;
  final ScrollController controller;
  final void Function(NotificationDto) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    final c = context.colors;
    final today = [
      for (final n in list.items)
        if (isTodayIst(n.createdAt)) n,
    ];
    final earlier = [
      for (final n in list.items)
        if (!isTodayIst(n.createdAt)) n,
    ];

    List<Widget> section(String title, List<NotificationDto> items) => [
      Padding(
        padding: const EdgeInsets.only(top: IdSpace.s2, bottom: IdSpace.s3),
        child: Semantics(
          header: true,
          child: Text(title, style: t.labelSm.copyWith(color: c.textMuted)),
        ),
      ),
      for (final n in items) ...[
        _Row(notification: n, onTap: () => onOpen(n)),
        const Divider(height: 1),
      ],
    ];

    return ListView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        IdSpace.s5,
        IdSpace.s5,
        IdSpace.s5,
        IdSpace.s6,
      ),
      children: [
        if (today.isNotEmpty) ...section('Today', today),
        if (earlier.isNotEmpty) ...section('Earlier', earlier),
        if (list.hasMore)
          list.moreFailed
              ? Center(
                  child: IdButton.text(
                    label: "Couldn't load more. Try again",
                    icon: LucideIcons.refreshCw,
                    onPressed: () =>
                        ref.read(notificationsProvider.notifier).loadMore(),
                  ),
                )
              : const Padding(
                  padding: EdgeInsets.all(IdSpace.s5),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.notification, required this.onTap});

  final NotificationDto notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final n = notification;
    final unread = n.readAt == null;
    final (icon, fg) = _look(context, n);

    return Semantics(
      button: true,
      label:
          '${unread ? 'Unread. ' : ''}${n.title}. ${n.body}. ${notificationTime(n.createdAt)}',
      excludeSemantics: true,
      child: IdCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: IdSpace.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: IdSize.iconMd, color: fg),
            const SizedBox(width: IdSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: t.title.copyWith(
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(n.body, style: t.body.copyWith(color: c.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    notificationTime(n.createdAt),
                    style: t.caption.copyWith(color: c.textMuted),
                  ),
                ],
              ),
            ),
            if (unread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 8, left: IdSpace.s2),
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Icon and colours for what the notification is about.
  (IconData, Color) _look(BuildContext context, NotificationDto n) {
    final c = context.colors;
    if (n.type == 'payment_received' || n.type == 'refund_processed') {
      return (
        n.type == 'payment_received'
            ? LucideIcons.circleCheck
            : LucideIcons.refreshCw,
        c.success,
      );
    }
    if (n.type == 'refund_failed') {
      return (LucideIcons.circleAlert, c.warning);
    }
    if (n.type.contains('offer') || n.type.contains('promo')) {
      return (LucideIcons.badgePercent, c.textMuted);
    }
    final status = n.data is Map ? (n.data as Map)['status'] : null;
    final icon = switch (status) {
      'PICKUP_ASSIGNED' ||
      'DELIVERY_ASSIGNED' ||
      'OUT_FOR_DELIVERY' => LucideIcons.truck,
      'PICKED_UP' => LucideIcons.shirt,
      'PROCESSING' || 'READY_FOR_DELIVERY' => LucideIcons.washingMachine,
      'DELIVERED' => LucideIcons.packageCheck,
      'CANCELLED' => LucideIcons.circleX,
      _ =>
        n.type.startsWith('refund')
            ? LucideIcons.refreshCw
            : LucideIcons.package,
    };
    return (icon, c.primary);
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget block(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(IdRadius.sm),
      ),
    );
    return Semantics(
      label: 'Loading notifications',
      child: ExcludeSemantics(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(IdSpace.s5),
          children: [
            for (var i = 0; i < 4; i++) ...[
              IdCard(
                child: Row(
                  children: [
                    block(IdSize.iconMd, IdSize.iconMd),
                    const SizedBox(width: IdSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                            widthFactor: .65,
                            child: block(double.infinity, 16),
                          ),
                          const SizedBox(height: 8),
                          FractionallySizedBox(
                            widthFactor: .9,
                            child: block(double.infinity, 14),
                          ),
                        ],
                      ),
                    ),
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
