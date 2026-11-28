import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../core/order_timeline.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/order_timeline.dart';
import '../../design/widgets/service_art.dart';
import '../../design/widgets/surfaces.dart';
import '../support/support.dart';
import 'care_note_view.dart';
import 'price_approval.dart';

/// The illustrated progress of an order that is still moving: each stage's picture fills in as it is reached, and the
/// current one says what is happening now and offers what the customer can do about it.
class OrderStages extends StatelessWidget {
  const OrderStages({super.key, required this.order});
  final OrderDto order;

  @override
  Widget build(BuildContext context) => IdCard(
        child: OrderTimeline(
          steps: buildTimeline(order),
          art: OrderTimeline.stageArt,
          now: OrderNow(order: order),
        ),
      );
}

/// "Now": one line on what is happening, and the action that fits.
class OrderNow extends StatelessWidget {
  const OrderNow({super.key, required this.order});
  final OrderDto order;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final action = stageAction(order);
    return Container(
      padding: const EdgeInsets.all(IdSpace.s3),
      decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(IdRadius.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(nowLine(order), style: t.body.copyWith(color: c.text, fontWeight: FontWeight.w500)),
          ),
          if (action != null) ...[
            const SizedBox(height: IdSpace.s2),
            Align(alignment: Alignment.centerLeft, child: StageActionButton(order: order, action: action)),
          ],
        ],
      ),
    );
  }
}

/// The button for a [StageAction].
class StageActionButton extends ConsumerWidget {
  const StageActionButton({super.key, required this.order, required this.action});
  final OrderDto order;
  final StageAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (action) {
        StageAction.approvePrice => IdButton(
            label: 'Review the new price',
            icon: LucideIcons.badgeIndianRupee,
            onPressed: () => showPriceApproval(context, order),
          ),
        // Orders cannot be edited after booking, so the note goes to the team on WhatsApp with the order number.
        StageAction.careNote => IdButton.tonal(
            label: hasCareNote(order) ? 'Add to your care note' : 'Add a care note',
            icon: LucideIcons.notebookPen,
            onPressed: () {
              final support = Support.of(ref);
              Support.whatsapp(support.phone, context: context, fallback: support, orderNumber: '${order.orderNumber} care note');
            },
          ),
        StageAction.reportIssue => IdButton.outline(
            label: 'Report an issue',
            icon: LucideIcons.messageSquareWarning,
            onPressed: () => context.push(Routes.report(order.id)),
          ),
      };
}

/// The last stage, for a delivered order: its picture, the line, and reporting a problem.
class DeliveredStage extends StatelessWidget {
  const DeliveredStage({super.key, required this.order});
  final OrderDto order;

  @override
  Widget build(BuildContext context) => IdCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServiceArtImage(OrderTimeline.stageArt.last, size: 56),
            const SizedBox(width: IdSpace.s3),
            Expanded(child: OrderNow(order: order)),
          ],
        ),
      );
}
