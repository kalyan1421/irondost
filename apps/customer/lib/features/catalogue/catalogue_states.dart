import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/state_view.dart';

/// Flat placeholders follow the item list without announcing dummy controls.
class CatalogueLoading extends StatelessWidget {
  const CatalogueLoading({super.key, this.showTabs = true});
  final bool showTabs;

  @override
  Widget build(BuildContext context) {
    Widget block(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceSoft,
        borderRadius: BorderRadius.circular(IdRadius.sm),
      ),
    );
    return Semantics(
      label: 'Loading prices',
      child: ExcludeSemantics(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(IdSpace.s5),
          children: [
            if (showTabs) ...[
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: IdSpace.s3),
                    Expanded(child: block(double.infinity, IdSize.touchTarget)),
                  ],
                ],
              ),
              const SizedBox(height: IdSpace.s6),
            ],
            for (var i = 0; i < 5; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: IdSpace.s4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                            widthFactor: .75,
                            child: block(double.infinity, 16),
                          ),
                          const SizedBox(height: IdSpace.s2),
                          block(56, 14),
                        ],
                      ),
                    ),
                    const SizedBox(width: IdSpace.s3),
                    block(76, IdSize.touchTarget),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class CatalogueFailure extends StatelessWidget {
  const CatalogueFailure({
    super.key,
    required this.failure,
    required this.onRetry,
  });
  final ApiFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListStateView(
    icon: failure.isConnectivity
        ? LucideIcons.wifiOff
        : LucideIcons.circleAlert,
    tone: StateTone.danger,
    announce: true,
    title: "Couldn't load prices",
    body:
        '${failure.isConnectivity ? 'Check your connection and try again.' : 'Please try again in a moment.'} Items already in your basket are kept.',
    action: IdButton.tonal(
      label: 'Try again',
      icon: LucideIcons.refreshCw,
      onPressed: onRetry,
    ),
  );
}

class CatalogueEmpty extends StatelessWidget {
  const CatalogueEmpty({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListStateView(
    icon: LucideIcons.shirt,
    title: 'No services right now',
    body:
        'No services are available to book. Check again for the latest prices.',
    action: IdButton.tonal(
      label: 'Check again',
      icon: LucideIcons.refreshCw,
      onPressed: onRetry,
    ),
  );
}
