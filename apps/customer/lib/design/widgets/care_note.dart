import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';

/// A quiet garment-care explanation, separate from errors and promotions.
class CareNote extends StatelessWidget {
  const CareNote({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(IdSpace.s4),
    decoration: BoxDecoration(
      color: context.colors.primarySoft,
      borderRadius: BorderRadius.circular(IdRadius.lg),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Icon(
            LucideIcons.shirt,
            size: IdSize.iconMd,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(width: IdSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.title),
              const SizedBox(height: IdSpace.s1),
              Text(
                body,
                style: context.text.caption.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
