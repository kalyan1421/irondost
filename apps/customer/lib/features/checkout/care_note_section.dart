import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_text_field.dart';
import '../../design/widgets/phrase_chip.dart';
import 'care_note.dart';
import 'checkout.dart';

/// "Anything we should know about your clothes?": a note for the team who clean them, with prompts for the services in the
/// basket and up to three photos. It is sent with the order as `careNote` and `carePhotoUrls`; the pickup note below it is
/// for the pickup partner.
class CareNoteSection extends ConsumerStatefulWidget {
  const CareNoteSection({super.key});

  @override
  ConsumerState<CareNoteSection> createState() => _CareNoteSectionState();
}

class _CareNoteSectionState extends ConsumerState<CareNoteSection> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(careNoteProvider).note,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String phrase) {
    final next = withCarePhrase(_controller.text, phrase);
    if (next == null) return;
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    ref.read(careNoteProvider.notifier).setNote(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    final care = ref.watch(careNoteProvider);
    final notifier = ref.read(careNoteProvider.notifier);
    final placing = ref.watch(checkoutProvider.select((s) => s.placing));
    final prompts = carePromptsFor(ref.watch(careServicesProvider));
    // The order was placed (or the customer signed out): the note starts over, and so does the field.
    ref.listen(careNoteProvider.select((s) => s.note), (_, next) {
      if (next != _controller.text) _controller.text = next;
    });
    final muted = t.caption.copyWith(color: c.textMuted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Anything we should know about your clothes?',
            style: t.titleLg,
          ),
        ),
        const SizedBox(height: IdSpace.s1),
        Text(
          'This is for the team who clean them. The pickup note below is for your pickup partner.',
          style: muted,
        ),
        const SizedBox(height: IdSpace.s4),
        if (prompts.isNotEmpty) ...[
          Wrap(
            spacing: IdSpace.s2,
            runSpacing: IdSpace.s2,
            children: [
              for (final phrase in prompts)
                PhraseChip(
                  label: phrase,
                  semanticLabel: 'Add "$phrase" to the care note',
                  selected: care.note.contains(phrase),
                  onTap: placing ? null : () => _add(phrase),
                ),
            ],
          ),
          const SizedBox(height: IdSpace.s4),
        ],
        IdTextField(
          key: const ValueKey('care-note-input'),
          label: 'Care note',
          hint: 'e.g. Red silk saree, stain on the sleeve',
          controller: _controller,
          enabled: !placing,
          minLines: 3,
          maxLines: 6,
          maxLength: careNoteMaxLength,
          textCapitalization: TextCapitalization.sentences,
          onChanged: notifier.setNote,
        ),
        const SizedBox(height: IdSpace.s4),
        Semantics(
          header: true,
          child: Text(
            'Photos (optional, up to $carePhotosMax)',
            style: t.labelSm,
          ),
        ),
        const SizedBox(height: IdSpace.s2),
        if (care.used > 0) ...[
          _Photos(
            care: care,
            enabled: !placing,
            onRemovePhoto: notifier.removePhoto,
            onRemovePending: notifier.removePending,
          ),
          const SizedBox(height: IdSpace.s3),
        ],
        if (care.used < carePhotosMax)
          IdButton.outline(
            label: care.used == 0 ? 'Add photos' : 'Add more photos',
            icon: LucideIcons.imagePlus,
            expand: true,
            onPressed: placing || care.uploading ? null : notifier.choosePhotos,
          ),
        if (care.uploading)
          Padding(
            padding: const EdgeInsets.only(top: IdSpace.s2),
            child: Semantics(
              liveRegion: true,
              child: Text('Uploading your photo…', style: muted),
            ),
          ),
        if (!care.uploading && care.pending.isNotEmpty) ...[
          const SizedBox(height: IdSpace.s2),
          IdButton.outline(
            label: 'Try the upload again',
            icon: LucideIcons.refreshCw,
            expand: true,
            onPressed: placing ? null : notifier.uploadPending,
          ),
          const SizedBox(height: IdSpace.s2),
          Text('Upload or remove this photo to book.', style: muted),
        ],
        if (care.error != null) ...[
          const SizedBox(height: IdSpace.s2),
          Semantics(liveRegion: true, child: IdFieldError(care.error!)),
        ],
        const SizedBox(height: IdSpace.s2),
        // Said where the photos are added: a stain photo helps us look, it does not promise a result.
        Text(
          'We will try to remove stains but cannot promise it.',
          style: muted,
        ),
      ],
    );
  }
}

/// The photos chosen, in the order they will be shown: sent ones first, then those still waiting.
class _Photos extends StatelessWidget {
  const _Photos({
    required this.care,
    required this.enabled,
    required this.onRemovePhoto,
    required this.onRemovePending,
  });

  final CareNoteState care;
  final bool enabled;
  final void Function(String url) onRemovePhoto;
  final void Function(String path) onRemovePending;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // Three tiles share a row, whatever the width.
        final size = ((box.maxWidth - 2 * IdSpace.s2) / carePhotosMax)
            .floorToDouble()
            .clamp(72.0, 120.0);
        return Wrap(
          spacing: IdSpace.s2,
          runSpacing: IdSpace.s2,
          children: [
            for (final (i, url) in care.photos.indexed)
              _Tile(
                size: size,
                label: 'Photo ${i + 1}',
                image: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _Broken(),
                ),
                onRemove: enabled ? () => onRemovePhoto(url) : null,
              ),
            for (final (i, path) in care.pending.indexed)
              _Tile(
                size: size,
                label: 'Photo ${care.photos.length + i + 1}, not sent yet',
                image: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _Broken(),
                ),
                state: care.uploading && i == 0
                    ? _TileState.sending
                    : _TileState.waiting,
                progress: care.uploading && i == 0 ? care.progress : null,
                onRemove: enabled ? () => onRemovePending(path) : null,
              ),
          ],
        );
      },
    );
  }
}

enum _TileState { sent, sending, waiting }

class _Tile extends StatelessWidget {
  const _Tile({
    required this.size,
    required this.label,
    required this.image,
    required this.onRemove,
    this.state = _TileState.sent,
    this.progress,
  });

  final double size;
  final String label;
  final Widget image;
  final VoidCallback? onRemove;
  final _TileState state;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            label: label,
            image: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(IdRadius.sm),
              child: ColoredBox(
                color: c.surfaceSoft,
                child: ExcludeSemantics(
                  child: state == _TileState.sent
                      ? image
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Opacity(opacity: 0.45, child: image),
                            Center(
                              child: state == _TileState.sending
                                  ? SizedBox.square(
                                      dimension: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        value: progress,
                                      ),
                                    )
                                  : Icon(
                                      LucideIcons.cloudAlert,
                                      color: c.warning,
                                    ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton(
              tooltip: 'Remove $label',
              onPressed: onRemove,
              icon: const Icon(LucideIcons.x),
              iconSize: 16,
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                minimumSize: const Size.square(28),
                backgroundColor: c.surface,
                foregroundColor: c.text,
                disabledBackgroundColor: c.surface,
                disabledForegroundColor: c.textMuted,
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Broken extends StatelessWidget {
  const _Broken();

  @override
  Widget build(BuildContext context) =>
      Center(child: Icon(LucideIcons.image, color: context.colors.textMuted));
}
