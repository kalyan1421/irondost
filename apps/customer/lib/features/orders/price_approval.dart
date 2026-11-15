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
    Widget lines(String label, List<AdjustmentLineDto> items) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(label, style: t.title),
      for (final line in items) Padding(padding: const EdgeInsets.symmetric(vertical: IdSpace.s2), child: Text(
        '${line.name}\n${line.quantity.toInt()} × ${rupees(line.unitPricePaise)} ${unitLabel(line.unit)} = ${rupees(line.lineTotalPaise)}', style: t.body)),
    ]);
    return PopScope(canPop: !busy, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Semantics(header: true, child: Text('Review the new total', style: t.titleLg)),
      Text(widget.order.orderNumber, style: t.orderId),
      const SizedBox(height: IdSpace.s3),
      Text(request.reason, style: t.bodyLg),
      const SizedBox(height: IdSpace.s3),
      lines('Accepted items', request.itemsBefore),
      Text('Accepted total: ${rupees(request.oldTotalPaise)}', style: t.title),
      const Divider(),
      lines('Proposed items', request.itemsAfter),
      Text('Items ${rupees(request.subtotalPaise)} · Discount ${rupees(request.discountPaise)} · Delivery ${rupees(request.deliveryFeePaise)}', style: t.body),
      Text('New total: ${rupees(request.newTotalPaise)}', style: t.titleLg),
      Text('Increase: ${rupees(request.newTotalPaise - request.oldTotalPaise)}', style: t.body),
      const SizedBox(height: IdSpace.s3),
      Text(pending ? 'Decide by ${istDateTimeLabel(request.expiresAt)}. If you decline or do not respond, the original bill stands. Our team will contact you about the item count.'
        : 'This request ${switch (request.status) {
            AdjustmentStatus.approved => 'was approved',
            AdjustmentStatus.declined => 'was declined',
            AdjustmentStatus.expired => 'expired',
            _ => 'is no longer waiting for your decision',
          }}. Open the order for your current bill.', style: t.body),
      if (error != null) Text(error!, style: t.body.copyWith(color: context.colors.danger)),
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
