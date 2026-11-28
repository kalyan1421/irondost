import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api_client.dart';
import '../auth/session.dart';
import '../basket/basket.dart';
import '../catalogue/catalogue.dart';
import '../issues/issues.dart';

/// The longest care note the API accepts (`careNote` is capped at 500 characters).
const careNoteMaxLength = 500;

/// Photos that can go with one order.
const carePhotosMax = 3;

/// The API refuses a photo bigger than this.
const _maxPhotoBytes = 8 * 1024 * 1024;

/// What a basket asks of the workshop. It decides which prompts sit under "Anything we should know about your clothes?".
enum CareService { dryCleaning, washing, ironing }

/// The kind of cleaning a price-list category is, from its slug (the way the artwork is chosen). Null for a category the
/// app has no prompts for.
CareService? careServiceOf(String slug) {
  final s = slug.toLowerCase();
  // Laundry before dry cleaning: "laundry" contains the letters "dry".
  if (s.contains('laundry') || s.contains('wash')) return CareService.washing;
  if (s.contains('dry')) return CareService.dryCleaning;
  if (s.contains('iron')) return CareService.ironing;
  return null;
}

/// Short phrases that start a care note. Each is a plain request, never a promise about the result.
const _prompts = {
  CareService.dryCleaning: [
    'Stain on a garment',
    'Delicate fabric',
    'Embroidery or beadwork',
    'Colour may run',
  ],
  CareService.washing: [
    'Colours may run',
    'Wash separately',
    'Wash whites separately',
    'No fabric softener',
    'Gentle wash',
    'Heavily soiled',
  ],
  CareService.ironing: ['Starch', 'Fold, do not hang'],
};

/// The prompts for [services], dry cleaning first, then washing, then ironing. A basket with dry cleaning and washing
/// asks about colours once.
List<String> carePromptsFor(Set<CareService> services) => [
  for (final service in CareService.values)
    if (services.contains(service))
      for (final phrase in _prompts[service]!)
        if (!(phrase == 'Colour may run' &&
            services.contains(CareService.washing)))
          phrase,
];

/// [text] with [phrase] added after it, or null when the phrase is already in the note or the note would pass the limit.
String? withCarePhrase(String text, String phrase) {
  final trimmed = text.trim();
  if (trimmed.contains(phrase)) return null;
  final separator = trimmed.isEmpty ? '' : (trimmed.endsWith('.') ? ' ' : '. ');
  final next = '$trimmed$separator$phrase';
  return next.length > careNoteMaxLength ? null : next;
}

/// The services in the basket, from the price list categories its items belong to.
final careServicesProvider = Provider<Set<CareService>>((ref) {
  final ids = ref.watch(basketProvider).lines.keys.toSet();
  final services =
      ref.watch(servicesProvider).value ?? const <CatalogCategoryDto>[];
  return {
    for (final category in services)
      if (category.items.any((i) => ids.contains(i.id)))
        ?careServiceOf(category.slug),
  };
});

/// Sends a photo for a care note. Kept apart from the report photos: they are stored and counted separately.
abstract class CarePhotoUploader {
  Future<String> upload(
    Uint8List bytes,
    String name, {
    CancelToken? cancelToken,
    void Function(int, int)? onProgress,
  });
}

class ApiCarePhotoUploader implements CarePhotoUploader {
  ApiCarePhotoUploader(this._dio);
  final Dio _dio;

  @override
  Future<String> upload(
    Uint8List bytes,
    String name, {
    CancelToken? cancelToken,
    void Function(int, int)? onProgress,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/me/uploads/care-photos',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: name),
      }),
      cancelToken: cancelToken,
      onSendProgress: onProgress,
    );
    return response.data!['url'] as String;
  }
}

final carePhotoUploaderProvider = Provider<CarePhotoUploader>(
  (ref) => ApiCarePhotoUploader(ref.watch(dioProvider)),
);

/// Reads a photo chosen on this phone. A provider so tests can answer without touching the disk.
final carePhotoReaderProvider = Provider<Future<Uint8List> Function(String path)>((ref) => (path) => XFile(path).readAsBytes());

@immutable
class CareNoteState {
  const CareNoteState({
    this.note = '',
    this.photos = const [],
    this.pending = const [],
    this.uploading = false,
    this.progress,
    this.error,
  });

  /// What the customer typed for the workshop.
  final String note;

  /// Photos that are uploaded and can go with the order, as the API gave them.
  final List<String> photos;

  /// Photos chosen on this phone that have not reached the API yet (local paths).
  final List<String> pending;
  final bool uploading;

  /// How much of the photo being sent has gone, 0 to 1.
  final double? progress;

  /// Why the last photo step did not work, in the customer's words.
  final String? error;

  /// Photos chosen, sent or not.
  int get used => photos.length + pending.length;

  /// A photo is still on its way or waiting for a retry: booking waits for it, or for the customer to remove it.
  bool get busy => uploading || pending.isNotEmpty;

  CareNoteState copyWith({
    String? note,
    List<String>? photos,
    List<String>? pending,
    bool? uploading,
    double? progress,
    bool clearProgress = false,
    String? error,
    bool clearError = false,
  }) => CareNoteState(
    note: note ?? this.note,
    photos: photos ?? this.photos,
    pending: pending ?? this.pending,
    uploading: uploading ?? this.uploading,
    progress: clearProgress ? null : (progress ?? this.progress),
    error: clearError ? null : (error ?? this.error),
  );
}

final careNoteProvider = NotifierProvider<CareNoteController, CareNoteState>(
  CareNoteController.new,
);

/// The care note and photos for the order being booked. Kept on the phone until the order is placed, so a closed app, a
/// call or a lost connection does not lose them.
class CareNoteController extends Notifier<CareNoteState> {
  static const _draftKey = 'care.draft.v1';

  /// Set while the system gallery is open, so photos Android hands back after it restarted the app can be picked up.
  static const _pickingKey = 'care.picking';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);
  CancelToken? _cancel;
  String? _sending;

  /// Changes when the draft is cleared, so an upload that finishes after that is dropped.
  int _generation = 0;

  @override
  CareNoteState build() {
    // The next customer on a shared phone starts with nothing: photos belong to the account that uploaded them.
    ref.listen(sessionProvider, (_, next) {
      if (next.value is SignedOut) clear();
    });
    ref.listen(issuePhotoRecoveryProvider, (_, next) {
      if (next.hasValue) _recover();
    });
    scheduleMicrotask(() {
      if (ref.mounted && ref.read(issuePhotoRecoveryProvider).hasValue) {
        _recover();
      }
    });
    ref.onDispose(() => _cancel?.cancel());
    return _restore();
  }

  CareNoteState _restore() {
    try {
      final data = jsonDecode(
        _prefs.getString(_draftKey) ?? '{}',
      ) as Map<String, dynamic>;
      final photos = (data['photos'] as List? ?? const [])
          .cast<String>()
          .take(carePhotosMax)
          .toList();
      final pending = (data['pending'] as List? ?? const [])
          .cast<String>()
          .take(carePhotosMax - photos.length)
          .toList();
      final note = (data['note'] as String? ?? '');
      return CareNoteState(
        note: note.length > careNoteMaxLength
            ? note.substring(0, careNoteMaxLength)
            : note,
        photos: photos,
        pending: pending,
      );
    } on Object {
      return const CareNoteState(); // A damaged optional draft must not get in the way of booking.
    }
  }

  Future<void> _save() async {
    final s = state;
    if (s.note.isEmpty && s.photos.isEmpty && s.pending.isEmpty) {
      await _prefs.remove(_draftKey);
    } else {
      await _prefs.setString(
        _draftKey,
        jsonEncode({'note': s.note, 'photos': s.photos, 'pending': s.pending}),
      );
    }
  }

  void setNote(String text) {
    state = state.copyWith(note: text);
    unawaited(_save());
  }

  /// Photos the system gallery handed back after Android restarted the app while it was open.
  void _recover() {
    if (_prefs.getBool(_pickingKey) != true) return;
    final paths = _prefs.getStringList('issue.recoveredPhotos') ?? const [];
    unawaited(_prefs.remove(_pickingKey));
    unawaited(_prefs.remove('issue.recoveredPhotos'));
    _addPending(paths);
  }

  void _addPending(Iterable<String> paths) {
    final room = carePhotosMax - state.used;
    final fresh = paths
        .where((p) => !state.pending.contains(p))
        .take(room)
        .toList();
    if (fresh.isEmpty) return;
    state = state.copyWith(
      pending: [...state.pending, ...fresh],
      clearError: true,
    );
    unawaited(_save().then((_) => uploadPending()));
  }

  /// Opens the gallery for the photos still allowed, then sends what was chosen.
  Future<void> choosePhotos() async {
    if (state.uploading || state.used >= carePhotosMax) return;
    state = state.copyWith(clearError: true);
    try {
      // The report screen has its own marker; two screens must not both claim one recovered photo.
      await _prefs.remove('issue.recoveryOrder');
      await _prefs.setBool(_pickingKey, true);
      final files = await ref
          .read(issuePhotoPickerProvider)
          .pick(carePhotosMax - state.used);
      await _prefs.remove(_pickingKey);
      _addPending(files.map((f) => f.path));
    } on Object {
      await _prefs.remove(_pickingKey);
      state = state.copyWith(
        error:
            'Could not open your photos. You can still book without a photo.',
      );
    }
  }

  /// Sends the photos still waiting, one after another. A photo that does not go stays waiting, to retry or remove.
  Future<void> uploadPending() async {
    if (state.uploading || state.pending.isEmpty) return;
    final generation = _generation;
    state = state.copyWith(
      uploading: true,
      clearError: true,
      clearProgress: true,
    );
    try {
      for (final path in [...state.pending]) {
        if (!state.pending.contains(path)) continue;
        final bytes = await ref.read(carePhotoReaderProvider)(path);
        if (bytes.length > _maxPhotoBytes) {
          _drop(path);
          state = state.copyWith(
            error: 'That photo is bigger than 8 MB. Choose a smaller one.',
          );
          continue;
        }
        _sending = path;
        _cancel = CancelToken();
        final url = await ref
            .read(carePhotoUploaderProvider)
            .upload(
              bytes,
              XFile(path).name,
              cancelToken: _cancel,
              onProgress: (sent, total) {
                if (generation == _generation && total > 0) {
                  state = state.copyWith(progress: sent / total);
                }
              },
            );
        if (generation != _generation) return;
        if (!state.pending.contains(path)) continue; // removed while it was on its way: the sent copy stays unused
        state = state.copyWith(
          photos: [...state.photos, url],
          pending: [...state.pending]..remove(path),
          clearProgress: true,
        );
        await _save();
      }
    } on Object catch (e) {
      // A cancelled upload is the customer removing the photo that was on its way: nothing went wrong.
      final removed = e is DioException && CancelToken.isCancel(e);
      if (generation == _generation && !removed) _uploadFailed(e);
    } finally {
      _sending = null;
      if (generation == _generation) {
        state = state.copyWith(uploading: false, clearProgress: true);
      }
    }
  }

  void _uploadFailed(Object e) {
    final failure = ApiFailure.from(e);
    if (failure.kind == ApiFailureKind.rejected) {
      // The API will not take this photo, now or on a retry (not an image, or the day's limit): say so and let it go.
      final path = _sending;
      if (path != null && failure.code == 'INVALID_IMAGE') {
        _drop(path);
      } else if (failure.code == 'PHOTO_LIMIT') {
        for (final p in [...state.pending]) {
          _drop(p);
        }
      }
      state = state.copyWith(
        error: failure.message ?? 'That photo could not be added. Choose another, or book without one.',
      );
      return;
    }
    state = state.copyWith(
      error: failure.isConnectivity
          ? "You're offline. Your photo is kept here. Reconnect, then try the upload again."
          : 'The photo did not upload. Try again, or remove it.',
    );
  }

  void _drop(String path) {
    state = state.copyWith(pending: [...state.pending]..remove(path));
    unawaited(_save());
  }

  /// Takes a photo that was sent off the order. It stays unused on the server.
  void removePhoto(String url) {
    state = state.copyWith(
      photos: [...state.photos]..remove(url),
      clearError: true,
    );
    unawaited(_save());
  }

  /// Takes away a photo that has not been sent, stopping its upload if it is the one on its way.
  void removePending(String path) {
    if (_sending == path) _cancel?.cancel();
    state = state.copyWith(
      pending: [...state.pending]..remove(path),
      clearError: true,
    );
    unawaited(_save());
  }

  /// The API would not take the photos (one was on another order, say): they come off the booking and the note stays.
  void photosRefused() {
    state = state.copyWith(
      photos: const [],
      pending: const [],
      error: "We couldn't use your photos, so they were taken off. Add them again if you still want them with this order.",
    );
    unawaited(_save());
  }

  /// The order is placed, or the customer signed out: the next one starts empty.
  void clear() {
    _generation++;
    _cancel?.cancel();
    _sending = null;
    state = const CareNoteState();
    unawaited(_prefs.remove(_draftKey));
  }
}
