import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/api_client.dart';
import '../theme.dart';

/// The admin category image, with branded 3D artwork while absent or unavailable.
class ServiceVisual extends StatelessWidget {
  const ServiceVisual({
    super.key,
    required this.category,
    this.size = 48,
    this.color,
  });
  final CatalogCategoryDto category;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final slug = category.slug.toLowerCase();
    final asset = slug.contains('wash')
        ? 'assets/services/wash-and-iron-3d.png'
        : slug.contains('dry')
        ? 'assets/services/dry-cleaning-3d.png'
        : slug.contains('iron')
        ? 'assets/services/ironing-3d.png'
        : null;
    final fallback = asset != null
        ? Image.asset(
            asset,
            fit: BoxFit.contain,
            cacheWidth: (size * 3).round(),
          )
        : Center(
            child: Icon(
              LucideIcons.shirt,
              size: size > 32 ? 28 : size,
              color: color ?? context.colors.primary,
            ),
          );
    final url = category.imageUrl?.trim();
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(IdRadius.sm),
          child: url == null || url.isEmpty
              ? fallback
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  cacheWidth: (size * 3).round(),
                  errorBuilder: (_, _, _) => fallback,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : fallback,
                ),
        ),
      ),
    );
  }
}
