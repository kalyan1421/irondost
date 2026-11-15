import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/surfaces.dart';

/// Whether the customer left the workshop a note or photos when booking.
bool hasCareNote(OrderDto order) => (order.careNote?.trim().isNotEmpty ?? false) || order.carePhotoUrls.isNotEmpty;

/// "Your care note": what the customer told the workshop about their clothes, with the photos they added. Tapping a photo
/// shows it larger. Callers show it only when [hasCareNote].
class OrderCareNote extends StatelessWidget {
  const OrderCareNote({super.key, required this.order});

  final OrderDto order;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final note = order.careNote?.trim() ?? '';
    final photos = order.carePhotoUrls;
    return IdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text('Your care note', style: t.title)),
          if (note.isNotEmpty) ...[const SizedBox(height: IdSpace.s2), Text(note, style: t.bodyLg)],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: IdSpace.s3),
            Wrap(
              spacing: IdSpace.s2,
              runSpacing: IdSpace.s2,
              children: [
                for (final (i, url) in photos.indexed) _Thumbnail(url: url, label: 'Photo ${i + 1} of ${photos.length}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      image: true,
      label: '$label, tap to enlarge',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(IdRadius.sm),
        onTap: () => showDialog<void>(context: context, builder: (_) => _Viewer(url: url, label: label)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(IdRadius.sm),
          child: SizedBox.square(
            dimension: 88,
            child: ColoredBox(
              color: context.colors.surfaceSoft,
              child: Image.network(url, fit: BoxFit.cover, cacheWidth: 264, errorBuilder: (_, _, _) => const _PhotoMissing()),
            ),
          ),
        ),
      ),
    );
  }
}

class _Viewer extends StatelessWidget {
  const _Viewer({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(IdSpace.s4),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(IdSpace.s2),
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                semanticLabel: label,
                errorBuilder: (_, _, _) => const Padding(padding: EdgeInsets.all(IdSpace.s6), child: _PhotoMissing()),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              tooltip: 'Close photo',
              icon: const Icon(LucideIcons.x),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(backgroundColor: context.colors.surface),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoMissing extends StatelessWidget {
  const _PhotoMissing();

  @override
  Widget build(BuildContext context) => Center(child: Icon(LucideIcons.image, color: context.colors.textMuted));
}
