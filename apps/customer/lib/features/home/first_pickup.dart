import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/surfaces.dart';
import '../addresses/addresses_controller.dart';
import '../basket/basket.dart';
import '../checkout/care_note.dart';
import '../orders/orders_list.dart';
import '../push/push_source.dart';
import '../schedule/schedule.dart';

/// Whether notifications are allowed on this phone. Read again each time the card is built afresh.
final pushPermissionProvider = FutureProvider.autoDispose<PushPermission>((ref) async {
  try {
    return await ref.watch(pushSourceProvider).permission();
  } catch (_) {
    return PushPermission.denied; // no push on this device
  }
});

enum FirstPickupStep { address, notifications, basket, slot, careNote }

/// One row of the checklist: done or not, and whether it can be skipped.
typedef FirstPickupItem = ({FirstPickupStep step, bool done, bool optional});

/// The checklist for a customer who has not had a delivery yet, worked out from what the app already holds. Null when
/// the card should not show: a delivery has happened, an order is on its way, or the orders have not loaded yet.
List<FirstPickupItem>? firstPickupChecklist({
  required OrderList? active,
  required OrderList? past,
  required bool hasAddress,
  required bool notificationsOn,
  required bool basketStarted,
  required bool slotPicked,
  required bool careNote,
}) {
  if (active == null || past == null) return null;
  if (active.items.isNotEmpty) return null; // the active order card takes over
  if (past.items.any((o) => o.status == OrderStatus.delivered)) return null;
  return [
    (step: FirstPickupStep.address, done: hasAddress, optional: false),
    (step: FirstPickupStep.notifications, done: notificationsOn, optional: false),
    (step: FirstPickupStep.basket, done: basketStarted, optional: false),
    (step: FirstPickupStep.slot, done: slotPicked, optional: false),
    (step: FirstPickupStep.careNote, done: careNote, optional: true),
  ];
}

/// "Ready for your first pickup?": what is done and what is left before the first booking, each row opening its screen.
class FirstPickupCard extends ConsumerWidget {
  const FirstPickupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Past orders are only loaded when nothing is in progress (the active order card covers that case).
    final active = ref.watch(ordersListProvider(Scope.active)).value;
    if (active == null || active.items.isNotEmpty) return const SizedBox.shrink();
    final care = ref.watch(careNoteProvider);
    final items = firstPickupChecklist(
      active: active,
      past: ref.watch(ordersListProvider(Scope.past)).value,
      hasAddress: ref.watch(addressesProvider).value?.isNotEmpty ?? false,
      notificationsOn: ref.watch(pushPermissionProvider).value == PushPermission.granted,
      basketStarted: ref.watch(basketCountProvider) > 0,
      slotPicked: ref.watch(scheduleChoiceProvider).pickup != null,
      careNote: care.note.trim().isNotEmpty || care.photos.isNotEmpty,
    );
    if (items == null) return const SizedBox.shrink();
    final c = context.colors;
    final t = context.text;
    final left = items.where((i) => !i.done && !i.optional).length;
    final basket = items.firstWhere((i) => i.step == FirstPickupStep.basket).done;
    final slot = items.firstWhere((i) => i.step == FirstPickupStep.slot).done;

    String routeFor(FirstPickupStep step) => switch (step) {
          FirstPickupStep.address => Routes.addresses,
          FirstPickupStep.notifications => Routes.notificationPermission,
          FirstPickupStep.basket => Routes.book,
          FirstPickupStep.slot => basket ? Routes.schedule : Routes.book,
          FirstPickupStep.careNote => !basket ? Routes.book : (slot ? Routes.checkout : Routes.schedule),
        };

    Future<void> open(FirstPickupStep step) async {
      final route = routeFor(step);
      if (route == Routes.addresses) {
        context.go(route);
        return;
      }
      await context.push<Object?>(route);
      if (step == FirstPickupStep.notifications) ref.invalidate(pushPermissionProvider);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: IdCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text('Ready for your first pickup?', style: t.titleLg)),
            const SizedBox(height: IdSpace.s1),
            Text(
              left == 0 ? 'All set. Book whenever you like.' : '$left ${left == 1 ? 'step' : 'steps'} to go',
              style: t.body.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: IdSpace.s3),
            for (final item in items) _Row(item: item, onTap: () => open(item.step)),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.onTap});
  final FirstPickupItem item;
  final VoidCallback onTap;

  static String label(FirstPickupStep s) => switch (s) {
        FirstPickupStep.address => 'Address saved',
        FirstPickupStep.notifications => 'Notifications on',
        FirstPickupStep.basket => 'Basket started',
        FirstPickupStep.slot => 'Time window picked',
        FirstPickupStep.careNote => 'Care note',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final name = label(item.step);
    return Semantics(
      button: true,
      label: '$name${item.optional ? ', optional' : ''}, ${item.done ? 'done' : 'not done yet'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(IdRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: IdSize.touchTarget),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.done ? c.success : c.surface,
                  border: item.done ? null : Border.all(color: c.borderStrong, width: 2),
                ),
                child: item.done ? Icon(LucideIcons.check, size: 14, color: c.onPrimary) : null,
              ),
              const SizedBox(width: IdSpace.s3),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: name,
                    children: [
                      if (item.optional) TextSpan(text: ' (optional)', style: t.body.copyWith(color: c.textMuted)),
                    ],
                  ),
                  style: t.bodyLg.copyWith(
                    color: item.done ? c.textMuted : c.text,
                    decoration: item.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Icon(LucideIcons.chevronRight, size: IdSize.iconSm, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
