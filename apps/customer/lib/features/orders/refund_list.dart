import 'package:flutter/material.dart';
import '../../core/money.dart';
import '../../core/order_text.dart';
import '../../core/slots.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';

class RefundList extends StatelessWidget {
  const RefundList({super.key, required this.order});
  final OrderDto order;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [for (final refund in order.refunds ?? const <RefundDto>[]) Padding(
      padding: const EdgeInsets.symmetric(vertical: IdSpace.s3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${rupees(refund.amountPaise)} · ${refundState(refund.status)}', style: context.text.title),
        Text(refundMethod(refund.method), style: context.text.body),
        Text(refund.note, style: context.text.body),
        Text(istDateTimeLabel(refund.processedAt ?? refund.createdAt), style: context.text.caption),
        if (refund.status == RefundStatus.failed) Text('The refund did not complete. Contact support.', style: context.text.body),
      ]),
    )],
  );
}
