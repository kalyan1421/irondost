import 'package:flutter/material.dart';

import '../theme.dart';

/// A plain labelled value with an optional action. Reflows when text needs more room.
class ReviewRow extends StatelessWidget {
  const ReviewRow({
    super.key,
    required this.label,
    required this.value,
    this.action,
  });
  final String label;
  final Widget value;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final labelledAction = action == null
        ? null
        : Semantics(
            label: 'Change ${label.toLowerCase()}',
            button: true,
            excludeSemantics: true,
            child: action!,
          );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.caption.copyWith(color: context.colors.textMuted),
        ),
        const SizedBox(height: IdSpace.s1),
        value,
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: IdSpace.s4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, box) => action == null
            ? content
            : (box.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  content,
                  const SizedBox(height: IdSpace.s2),
                  labelledAction!,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: content),
                  const SizedBox(width: IdSpace.s2),
                  labelledAction!,
                ],
              ),
      ),
    );
  }
}
