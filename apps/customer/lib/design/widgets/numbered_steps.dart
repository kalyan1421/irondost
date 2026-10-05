import 'package:flutter/material.dart';

import '../theme.dart';

/// A short ordered list: a number, a title and one or two lines under it, in divided rows. For what
/// happens in what order ("What happens next", "How it works"), not for choices.
class NumberedSteps extends StatelessWidget {
  const NumberedSteps({super.key, required this.steps});

  /// (title, body) in order.
  final List<(String, String)> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (title, body)) in steps.indexed)
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: c.border),
                bottom: i == steps.length - 1
                    ? BorderSide(color: c.border)
                    : BorderSide.none,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: IdSpace.s3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: SizedBox(
                    width: IdSpace.s5,
                    child: Text(
                      '${i + 1}',
                      style: t.label.copyWith(color: c.primary),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: t.label),
                      const SizedBox(height: IdSpace.s1),
                      Text(body, style: t.body.copyWith(color: c.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
