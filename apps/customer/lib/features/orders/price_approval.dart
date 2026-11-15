import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/money.dart';
import '../../core/slots.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_sheet.dart';
import '../../design/widgets/surfaces.dart';
import '../catalogue/catalogue.dart';
import 'order_repository.dart';
import 'orders_list.dart';

abstract class AdjustmentRepository {
  Future<OrderDto> decide(String orderId, String adjustmentId, {required bool approve});
}

class ApiAdjustmentRepository implements AdjustmentRepository {
  ApiAdjustmentRepository(this.api);
  final IronDostApi api;
  @override
  Future<OrderDto> decide(String orderId, String adjustmentId, {required bool approve}) => approve
    ? api.orders.ordersControllerApprove(id: orderId, adjustmentId: adjustmentId)
    : api.orders.ordersControllerDecline(id: orderId, adjustmentId: adjustmentId);
}

final adjustmentRepositoryProvider = Provider<AdjustmentRepository>((ref) => ApiAdjustmentRepository(ref.watch(apiProvider)));

class PriceApprovalCard extends StatelessWidget {
  const PriceApprovalCard({super.key, required this.order});
  final OrderDto order;
  @override
  Widget build(BuildContext context) {
    final requests = order.adjustments ?? const <OrderAdjustmentDto>[];
    if (requests.isEmpty) return const SizedBox.shrink();
    final request = requests.first;
    final pending = request.status == AdjustmentStatus.pendingCustomer;
    final title = switch (request.status) {
      AdjustmentStatus.pendingCustomer => 'Your total needs your OK',
      AdjustmentStatus.approved => 'New total approved',
      AdjustmentStatus.declined => 'New total declined',
      AdjustmentStatus.expired => 'Price request expired',
      _ => 'Price request',
    };
    return Padding(padding: const EdgeInsets.only(bottom: IdSpace.s4), child: IdCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(header: true, child: Text(title, style: context.text.title)),
        Text('${rupees(request.oldTotalPaise)} → ${rupees(request.newTotalPaise)}', style: context.text.bodyLg),
        Text(pending ? 'Your accepted bill stays unchanged until you approve.' : request.status == AdjustmentStatus.approved
          ? 'The approved bill now applies.' : 'Your original bill stands.', style: context.text.body),
        IdButton.outline(label: 'Review price change', onPressed: () => showIdSheet<void>(context,
          builder: (_) => _ApprovalSheet(order: order, request: request))),
      ],
    )));
  }
}

class _ApprovalSheet extends ConsumerStatefulWidget {
  const _ApprovalSheet({required this.order, required this.request});
  final OrderDto order;
  final OrderAdjustmentDto request;
  @override
  ConsumerState<_ApprovalSheet> createState() => _ApprovalSheetState();
}

class _ApprovalSheetState extends ConsumerState<_ApprovalSheet> {
  bool busy = false;
  bool terminal = false;
  String? error;
  Future<void> decide(bool approve) async {
    if (busy) return;
    setState(() { busy = true; error = null; });
    try {
      await ref.read(adjustmentRepositoryProvider).decide(widget.order.id, widget.request.id, approve: approve);
      ref.invalidate(orderProvider(widget.order.id));
      ref.invalidate(ordersListProvider(Scope.active));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final failure = ApiFailure.from(e);
      setState(() {
        busy = false;
        terminal = ['ADJUSTMENT_DECIDED', 'ADJUSTMENT_EXPIRED', 'ORDER_CHANGED'].contains(failure.code);
        error = terminal ? 'This request changed or expired. Close and refresh the order for the current bill.'
          : 'Could not save your decision. Your accepted bill has not been changed by this screen. Try again.';
      });
      if (terminal) ref.invalidate(orderProvider(widget.order.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final pending = request.status == AdjustmentStatus.pendingCustomer && !terminal;
    final t = context.text;
    final changes = _lineChanges(request.itemsBefore, request.itemsAfter);
    return PopScope(canPop: !busy, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Semantics(header: true, child: Text('Review the new total', style: t.titleLg)),
      Text(widget.order.orderNumber, style: t.orderId),
      const SizedBox(height: IdSpace.s3),
      Text(request.reason, style: t.bodyLg),
      const SizedBox(height: IdSpace.s5),
      Text('What changed', style: t.title),
      for (var i = 0; i < changes.length; i++) ...[
        if (i > 0) Divider(height: 1, color: context.colors.border),
        _ChangeRow(changes[i]),
      ],
      const SizedBox(height: IdSpace.s4),
      _TotalsPanel(request, currentTravelPaise: widget.order.deliveryFeePaise),
      const SizedBox(height: IdSpace.s4),
      Text(pending ? 'Decide by ${istDateTimeLabel(request.expiresAt)}. If you decline or do not respond, the original bill stands. Our team will contact you about the item count.'
        : 'This request ${switch (request.status) {
            AdjustmentStatus.approved => 'was approved',
            AdjustmentStatus.declined => 'was declined',
            AdjustmentStatus.expired => 'expired',
            _ => 'is no longer waiting for your decision',
          }}. Open the order for your current bill.', style: t.body),
      if (error != null) Padding(padding: const EdgeInsets.only(top: IdSpace.s3), child: Text(error!, style: t.body.copyWith(color: context.colors.danger))),
      const SizedBox(height: IdSpace.s4),
      if (pending) ...[
        IdButton(label: 'Approve ${rupees(request.newTotalPaise)}', loading: busy, onPressed: () => decide(true), expand: true),
        const SizedBox(height: IdSpace.s2),
        IdButton.outline(label: 'Decline new total', onPressed: busy ? null : () => decide(false), expand: true),
      ],
      IdButton.text(label: 'Close', onPressed: busy ? null : () => Navigator.of(context).pop()),
    ]));
  }
}

/// One item as the accepted bill had it and as the new bill has it. Either side is null when the item is new or gone.
class _LineChange {
  const _LineChange(this.before, this.after);
  final AdjustmentLineDto? before;
  final AdjustmentLineDto? after;

  AdjustmentLineDto get line => (after ?? before)!;
  bool get added => before == null;
  bool get removed => after == null;
  bool get changed => before != null && after != null && (before!.quantity != after!.quantity || before!.unitPricePaise != after!.unitPricePaise);
  bool get touched => added || removed || changed;
}

/// Changed items first, so the difference is the first thing read; unchanged items keep their order below.
List<_LineChange> _lineChanges(List<AdjustmentLineDto> before, List<AdjustmentLineDto> after) {
  String key(AdjustmentLineDto l) => l.catalogItemId ?? l.name;
  final old = {for (final l in before) key(l): l};
  final all = [for (final l in after) _LineChange(old.remove(key(l)), l), for (final l in old.values) _LineChange(l, null)];
  return [...all.where((c) => c.touched), ...all.where((c) => !c.touched)];
}

String _number(num n) => n == n.toInt() ? '${n.toInt()}' : '$n';
String _unitSuffix(ItemUnit unit) => switch (unit) {
  ItemUnit.kg => ' kg', ItemUnit.pair => ' pairs', ItemUnit.valueSet => ' sets', _ => '',
};

class _ChangeRow extends StatelessWidget {
  const _ChangeRow(this.change);
  final _LineChange change;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final line = change.line;
    final unit = _unitSuffix(line.unit);
    final (tag, tagBg, tagFg) = change.added
        ? ('New', c.successSoft, c.success)
        : change.removed
        ? ('Removed', c.surfaceSoft, c.textMuted)
        : change.changed
        ? ('${_number(change.before!.quantity)} → ${_number(change.after!.quantity)}$unit', c.primarySoft, c.onPrimarySoft)
        : (null, c.surface, c.text);
    final rate = '${rupees(line.unitPricePaise)} ${unitLabel(line.unit)}';
    // An item that is only changing keeps its rate; every other row also says how many.
    final caption = change.changed ? rate : '${_number(line.quantity)}$unit × $rate';
    final muted = !change.touched || change.removed;
    final strike = t.body.copyWith(color: c.textMuted, decoration: TextDecoration.lineThrough);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: IdSpace.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.name, style: t.title.copyWith(color: muted ? c.textMuted : null)),
                  const SizedBox(height: IdSpace.s1),
                  Wrap(
                    spacing: IdSpace.s2,
                    runSpacing: IdSpace.s1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (tag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(IdRadius.full)),
                          child: Text(tag, style: t.labelSm.copyWith(color: tagFg)),
                        ),
                      Text(caption, style: t.body.copyWith(color: c.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: IdSpace.s3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (change.changed) Text(rupees(change.before!.lineTotalPaise), style: strike),
                Text(
                  rupees(line.lineTotalPaise),
                  style: change.removed ? strike : t.title.copyWith(color: muted ? c.textMuted : null),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The new bill's arithmetic, amounts on the right: items, discount and travel charge, then accepted total, the increase,
/// and the new total as the one large figure. The travel charge row shows the old and the new charge when a new count
/// moved it (reaching the free-travel amount removes it, falling under adds it).
class _TotalsPanel extends StatelessWidget {
  const _TotalsPanel(this.request, {required this.currentTravelPaise});
  final OrderAdjustmentDto request;

  /// The travel charge on the bill the customer has accepted.
  final num currentTravelPaise;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final delta = request.newTotalPaise - request.oldTotalPaise;
    return Container(
      padding: const EdgeInsets.all(IdSpace.s4),
      decoration: BoxDecoration(color: c.surfaceSoft, borderRadius: BorderRadius.circular(IdRadius.lg)),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AmountRow('Items', rupees(request.subtotalPaise)),
            if (request.discountPaise > 0) _AmountRow('Discount', '−${rupees(request.discountPaise)}'),
            if (request.deliveryFeePaise != currentTravelPaise)
              _AmountRow(
                'Travel charge',
                travelChargeLabel(request.deliveryFeePaise),
                was: travelChargeLabel(currentTravelPaise),
              )
            else
              _AmountRow('Travel charge', travelChargeLabel(request.deliveryFeePaise)),
            Padding(padding: const EdgeInsets.symmetric(vertical: IdSpace.s3), child: Divider(height: 1, color: c.border)),
            _AmountRow('Accepted total', rupees(request.oldTotalPaise), muted: true),
            _AmountRow(delta >= 0 ? 'Increase' : 'Decrease', '${delta >= 0 ? '+' : '−'}${rupees(delta.abs())}', emphasis: true),
            const SizedBox(height: IdSpace.s3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text('New total', style: t.title)),
                const SizedBox(width: IdSpace.s3),
                Text(rupees(request.newTotalPaise), style: t.headline),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(this.label, this.value, {this.muted = false, this.emphasis = false, this.was});
  final String label;
  final String value;
  final bool muted;
  final bool emphasis;

  /// The amount this row had on the accepted bill, shown struck through before the new one when it changed.
  final String? was;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final style = (emphasis ? t.title : t.bodyLg).copyWith(color: muted ? c.textMuted : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: IdSpace.s3),
          if (was == null)
            Text(value, style: style, textAlign: TextAlign.end)
          else
            Text.rich(
              TextSpan(children: [
                TextSpan(text: was, style: style.copyWith(color: c.textMuted, decoration: TextDecoration.lineThrough)),
                const TextSpan(text: ' '),
                TextSpan(text: value),
              ]),
              style: style,
              textAlign: TextAlign.end,
              semanticsLabel: '$value, was $was',
            ),
        ],
      ),
    );
  }
}
