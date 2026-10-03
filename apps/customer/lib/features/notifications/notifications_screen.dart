import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/slots.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/surfaces.dart';
import 'notifications.dart';

/// The inbox: what happened to the customer's orders and payments, newest first, grouped Today / Earlier.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.extentAfter < 400) ref.read(notificationsProvider.notifier).loadMore();
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
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home)),
        title: Text('Notifications', style: context.text.titleLg),
        actions: [
          if ((list?.unread ?? 0) > 0) TextButton(onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(), child: const Text('Mark all read')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          await ref.read(notificationsProvider.future).then((_) {}, onError: (_) {});
        },
        child: async.when(
          loading: () => list == null ? const _Skeleton() : _Body(list: list, controller: _scroll, onOpen: _open),
          error: (e, _) => list != null ? _Body(list: list, controller: _scroll, onOpen: _open) : _Failure(offline: ApiFailure.from(e).isConnectivity, onRetry: () => ref.invalidate(notificationsProvider)),
          data: (list) => list.items.isEmpty ? const _Empty() : _Body(list: list, controller: _scroll, onOpen: _open),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.list, required this.controller, required this.onOpen});

  final NotificationList list;
  final ScrollController controller;
  final void Function(NotificationDto) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    final c = context.colors;
    final today = [for (final n in list.items) if (isTodayIst(n.createdAt)) n];
    final earlier = [for (final n in list.items) if (!isTodayIst(n.createdAt)) n];

    List<Widget> section(String title, List<NotificationDto> items) => [
          Padding(
            padding: const EdgeInsets.only(top: IdSpace.s2, bottom: IdSpace.s3),
            child: Semantics(header: true, child: Text(title, style: t.labelSm.copyWith(color: c.textMuted))),
          ),
          for (final n in items) ...[_Row(notification: n, onTap: () => onOpen(n)), const SizedBox(height: IdSpace.s3)],
        ];

    return ListView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(IdSpace.s4, IdSpace.s4, IdSpace.s4, IdSpace.s6),
      children: [
        if (today.isNotEmpty) ...section('Today', today),
        if (earlier.isNotEmpty) ...section('Earlier', earlier),
        if (list.hasMore)
          list.moreFailed
              ? Center(child: IdButton.text(label: "Couldn't load more. Try again", icon: LucideIcons.refreshCw, onPressed: () => ref.read(notificationsProvider.notifier).loadMore()))
              : const Padding(padding: EdgeInsets.all(IdSpace.s4), child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)))),
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
    final (icon, bg, fg) = _look(context, n);

    return Semantics(
      button: true,
      label: '${unread ? 'Unread. ' : ''}${n.title}. ${n.body}. ${notificationTime(n.createdAt)}',
      excludeSemantics: true,
      child: IdCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: IdSpace.s4, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(IdRadius.sm)), child: Icon(icon, size: IdSize.iconMd, color: fg)),
            const SizedBox(width: IdSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: t.title.copyWith(fontWeight: unread ? FontWeight.w600 : FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(n.body, style: t.body.copyWith(color: c.textMuted)),
                  const SizedBox(height: 2),
                  Text(notificationTime(n.createdAt), style: t.caption.copyWith(color: c.textMuted)),
                ],
              ),
            ),
            if (unread) Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 8, left: IdSpace.s2), decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  /// Icon and colours for what the notification is about.
  (IconData, Color, Color) _look(BuildContext context, NotificationDto n) {
    final c = context.colors;
    if (n.type == 'payment_received' || n.type == 'refund_processed') return (n.type == 'payment_received' ? LucideIcons.circleCheck : LucideIcons.refreshCw, c.successSoft, c.success);
    if (n.type == 'refund_failed') return (LucideIcons.circleAlert, c.warningSoft, c.warning);
    if (n.type.contains('offer') || n.type.contains('promo')) return (LucideIcons.badgePercent, c.offer, c.onOffer);
    final status = n.data is Map ? (n.data as Map)['status'] : null;
    final icon = switch (status) {
      'PICKUP_ASSIGNED' || 'DELIVERY_ASSIGNED' || 'OUT_FOR_DELIVERY' => LucideIcons.truck,
      'PICKED_UP' => LucideIcons.shirt,
      'PROCESSING' || 'READY_FOR_DELIVERY' => LucideIcons.washingMachine,
      'DELIVERED' => LucideIcons.packageCheck,
      'CANCELLED' => LucideIcons.circleX,
      _ => n.type.startsWith('refund') ? LucideIcons.refreshCw : LucideIcons.package,
    };
    return (icon, c.surfaceSoft, c.primary);
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget block(double w, double h) => Container(width: w, height: h, decoration: BoxDecoration(color: c.surfaceSoft, borderRadius: BorderRadius.circular(IdRadius.sm)));
    return Semantics(
      label: 'Loading notifications',
      child: ExcludeSemantics(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(IdSpace.s4),
          children: [
            for (var i = 0; i < 4; i++) ...[
              IdCard(child: Row(children: [block(40, 40), const SizedBox(width: IdSpace.s3), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [block(150, 16), const SizedBox(height: 8), block(220, 14)]))])),
              const SizedBox(height: IdSpace.s3),
            ],
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
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
                  SizedBox(
                    width: 132,
                    height: 124,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(width: 120, height: 120, decoration: BoxDecoration(color: c.surfaceSoft, shape: BoxShape.circle), child: ExcludeSemantics(child: Icon(LucideIcons.bell, size: 52, color: c.primary))),
                        const Positioned(right: 0, top: 6, child: Bubble(22)),
                      ],
                    ),
                  ),
                  const SizedBox(height: IdSpace.s4),
                  Semantics(header: true, child: Text("You're all caught up", style: t.titleLg, textAlign: TextAlign.center)),
                  const SizedBox(height: IdSpace.s2),
                  Text('Updates on your orders and payments will appear here.', style: t.bodyLg.copyWith(color: c.textMuted), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.offline, required this.onRetry});
  final bool offline;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
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
                  Container(width: 96, height: 96, decoration: BoxDecoration(color: c.dangerSoft, shape: BoxShape.circle), child: Icon(offline ? LucideIcons.wifiOff : LucideIcons.circleAlert, size: 44, color: c.danger)),
                  const SizedBox(height: IdSpace.s4),
                  Semantics(header: true, liveRegion: true, child: Text("Couldn't load notifications", style: t.titleLg, textAlign: TextAlign.center)),
                  const SizedBox(height: IdSpace.s2),
                  Text(offline ? "You're offline. Check your connection and try again." : 'Please try again in a moment.', style: t.bodyLg.copyWith(color: c.textMuted), textAlign: TextAlign.center),
                  const SizedBox(height: IdSpace.s4),
                  IdButton.tonal(label: 'Try again', icon: LucideIcons.refreshCw, onPressed: onRetry),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
