import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/addresses/address_repository.dart';
import 'package:irondost_customer/features/auth/session.dart';
import 'package:irondost_customer/features/basket/basket.dart';
import 'package:irondost_customer/features/catalogue/catalogue.dart';
import 'package:irondost_customer/features/checkout/care_note.dart';
import 'package:irondost_customer/features/checkout/checkout.dart';
import 'package:irondost_customer/features/issues/issues.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/schedule/schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

/// A gallery that hands back the paths a test puts in [next].
class FakePhotoPicker implements IssuePhotoPicker {
  List<String> next = [];
  final asked = <int>[];

  @override
  Future<List<XFile>> pick(int remaining) async {
    asked.add(remaining);
    return [for (final path in next.take(remaining)) XFile(path)];
  }

  @override
  Future<List<XFile>> recover() async => [];
}

/// The care photo upload: answers with a URL per file, or fails the way a test queues.
class FakeCareUploader implements CarePhotoUploader {
  final sent = <String>[];
  final failures = <Object>[];
  Completer<void>? hold;

  @override
  Future<String> upload(
    Uint8List bytes,
    String name, {
    CancelToken? cancelToken,
    void Function(int, int)? onProgress,
  }) async {
    onProgress?.call(1, 2);
    if (hold != null) await hold!.future;
    if (failures.isNotEmpty) throw failures.removeAt(0);
    sent.add(name);
    return 'https://files.test/care/u1/$name.webp';
  }
}

const _basketOfShirts = {'basket.v1': '{"lines":{"shirt":2},"promoCode":null}'};

void main() {
  group('prompts for the services in the basket', () {
    test('a category is the kind of cleaning its slug says', () {
      expect(careServiceOf('dry-cleaning'), CareService.dryCleaning);
      expect(careServiceOf('Wash-and-Iron'), CareService.washing);
      expect(careServiceOf('ironing'), CareService.ironing);
      expect(careServiceOf('shoe-care'), isNull);
    });

    test(
      'dry cleaning asks about stains, delicate fabric, embroidery and colour',
      () {
        expect(carePromptsFor({CareService.dryCleaning}), [
          'Stain on a garment',
          'Delicate fabric',
          'Embroidery or beadwork',
          'Colour may run',
        ]);
      },
    );

    test('washing asks about colours, whites, softener, a gentle wash and heavy soil', () {
      expect(carePromptsFor({CareService.washing}), [
        'Colours may run',
        'Wash separately',
        'Wash whites separately',
        'No fabric softener',
        'Gentle wash',
        'Heavily soiled',
      ]);
    });

    test('a laundry category asks the washing questions', () {
      expect(careServiceOf('laundry'), CareService.washing);
      expect(careServiceOf('laundry-wash-fold'), CareService.washing);
    });

    test('ironing asks about starch and folding', () {
      expect(carePromptsFor({CareService.ironing}), [
        'Starch',
        'Fold, do not hang',
      ]);
    });

    test(
      'a mixed basket gets each service once, and colours are asked about once',
      () {
        expect(
          carePromptsFor({
            CareService.ironing,
            CareService.dryCleaning,
            CareService.washing,
          }),
          [
            'Stain on a garment',
            'Delicate fabric',
            'Embroidery or beadwork',
            'Colours may run',
            'Wash separately',
            'Wash whites separately',
            'No fabric softener',
            'Gentle wash',
            'Heavily soiled',
            'Starch',
            'Fold, do not hang',
          ],
        );
      },
    );

    test('a basket with no known service gets no prompts', () {
      expect(carePromptsFor({}), isEmpty);
    });
  });

  group('adding a prompt to the note', () {
    test('goes after what is there, once, and only if it fits', () {
      expect(withCarePhrase('', 'Starch'), 'Starch');
      expect(withCarePhrase('Red saree', 'Starch'), 'Red saree. Starch');
      expect(withCarePhrase('Red saree.', 'Starch'), 'Red saree. Starch');
      expect(withCarePhrase('  Red saree  ', 'Starch'), 'Red saree. Starch');
      expect(withCarePhrase('Red saree. Starch', 'Starch'), isNull);
      expect(withCarePhrase('a' * careNoteMaxLength, 'Starch'), isNull);
      expect(
        withCarePhrase('a' * (careNoteMaxLength - 8), 'Starch'),
        'a' * (careNoteMaxLength - 8) + '. Starch',
      );
    });
  });

  group('the draft', () {
    late FakePhotoPicker picker;
    late FakeCareUploader uploader;
    late ProviderContainer container;
    late SharedPreferences prefs;
    var sizes = <String, int>{};

    Future<void> open({Map<String, Object> saved = const {}}) async {
      picker = FakePhotoPicker();
      uploader = FakeCareUploader();
      sizes = {};
      final overrides = await basketOverrides(saved: saved);
      container = ProviderContainer(
        overrides: [
          ...overrides,
          issuePhotoPickerProvider.overrideWithValue(picker),
          carePhotoUploaderProvider.overrideWithValue(uploader),
          carePhotoReaderProvider.overrideWithValue(
            (path) async => Uint8List(sizes[path] ?? 1024),
          ),
        ],
      );
      addTearDown(container.dispose);
      prefs = container.read(sharedPreferencesProvider);
    }

    CareNoteController care() => container.read(careNoteProvider.notifier);
    CareNoteState state() => container.read(careNoteProvider);
    Map<String, dynamic> saved() =>
        jsonDecode(prefs.getString('care.draft.v1')!) as Map<String, dynamic>;
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('starts empty', () async {
      await open();
      expect(state().note, '');
      expect(state().photos, isEmpty);
      expect(state().busy, isFalse);
    });

    test('keeps what is typed, and comes back with it', () async {
      await open();
      care().setNote('Stain on the collar');
      await settle();
      expect(saved()['note'], 'Stain on the collar');

      final raw = prefs.getString('care.draft.v1')!;
      await open(saved: {'care.draft.v1': raw});
      expect(state().note, 'Stain on the collar');
    });

    test(
      'comes back with its photos, those sent and those waiting, at most three',
      () async {
        await open(
          saved: {
            'care.draft.v1': jsonEncode({
              'note': 'Silk saree',
              'photos': [
                'https://files.test/a.webp',
                'https://files.test/b.webp',
              ],
              'pending': ['/tmp/c.jpg', '/tmp/d.jpg'],
            }),
          },
        );
        expect(state().note, 'Silk saree');
        expect(state().photos, [
          'https://files.test/a.webp',
          'https://files.test/b.webp',
        ]);
        expect(state().pending, ['/tmp/c.jpg']);
        expect(
          state().busy,
          isTrue,
          reason:
              'a waiting photo holds booking back until it is sent or removed',
        );
      },
    );

    test('a damaged draft is ignored', () async {
      await open(saved: {'care.draft.v1': '{not json'});
      expect(state().note, '');
      expect(state().photos, isEmpty);
    });

    test(
      'is forgotten once the order is placed or the customer signs out',
      () async {
        await open();
        care().setNote('Stain');
        await settle();
        care().clear();
        expect(state().note, '');
        expect(prefs.getString('care.draft.v1'), isNull);

        care().setNote('Another note');
        await settle();
        container.read(sessionProvider.notifier).state = const AsyncData(
          SignedOut(),
        );
        await settle();
        expect(state().note, '');
        expect(prefs.getString('care.draft.v1'), isNull);
      },
    );
  });

  group('photos', () {
    late FakePhotoPicker picker;
    late FakeCareUploader uploader;
    late ProviderContainer container;
    late SharedPreferences prefs;
    var sizes = <String, int>{};

    Future<void> open() async {
      picker = FakePhotoPicker();
      uploader = FakeCareUploader();
      sizes = {};
      container = ProviderContainer(
        overrides: [
          ...await basketOverrides(),
          issuePhotoPickerProvider.overrideWithValue(picker),
          carePhotoUploaderProvider.overrideWithValue(uploader),
          carePhotoReaderProvider.overrideWithValue(
            (path) async => Uint8List(sizes[path] ?? 1024),
          ),
        ],
      );
      addTearDown(container.dispose);
      prefs = container.read(sharedPreferencesProvider);
    }

    CareNoteController care() => container.read(careNoteProvider.notifier);
    CareNoteState state() => container.read(careNoteProvider);
    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('are chosen, sent one after another and kept in the draft', () async {
      await open();
      picker.next = ['/tmp/one.jpg', '/tmp/two.jpg'];
      await care().choosePhotos();
      await settle();

      expect(picker.asked, [carePhotosMax]);
      expect(uploader.sent, ['one.jpg', 'two.jpg']);
      expect(state().photos, [
        'https://files.test/care/u1/one.jpg.webp',
        'https://files.test/care/u1/two.jpg.webp',
      ]);
      expect(state().pending, isEmpty);
      expect(state().busy, isFalse);
      expect(
        (jsonDecode(prefs.getString('care.draft.v1')!)
            as Map<String, dynamic>)['photos'],
        hasLength(2),
      );
    });

    test('only the places still free are offered, and no more than three are taken', () async {
      await open();
      picker.next = ['/tmp/1.jpg', '/tmp/2.jpg'];
      await care().choosePhotos();
      await settle();
      picker.next = ['/tmp/3.jpg', '/tmp/4.jpg', '/tmp/5.jpg'];
      await care().choosePhotos();
      await settle();

      expect(picker.asked, [3, 1]);
      expect(state().photos, hasLength(3));
      // Nothing left to add: the gallery is not opened again.
      await care().choosePhotos();
      expect(picker.asked, [3, 1]);
    });

    test('a photo that cannot go while offline waits, and is sent when the customer retries', () async {
      await open();
      uploader.failures.add(const ApiFailure(ApiFailureKind.offline));
      picker.next = ['/tmp/one.jpg'];
      await care().choosePhotos();
      await settle();

      expect(state().pending, ['/tmp/one.jpg']);
      expect(state().photos, isEmpty);
      expect(state().busy, isTrue);
      expect(state().error, contains("You're offline"));
      expect(
        (jsonDecode(prefs.getString('care.draft.v1')!)
            as Map<String, dynamic>)['pending'],
        ['/tmp/one.jpg'],
      );

      await care().uploadPending();
      expect(state().pending, isEmpty);
      expect(state().photos, hasLength(1));
      expect(state().error, isNull);
      expect(state().busy, isFalse);
    });

    test(
      'a photo that fails for another reason waits too, with a plain message',
      () async {
        await open();
        uploader.failures.add(
          const ApiFailure(ApiFailureKind.server, statusCode: 500),
        );
        picker.next = ['/tmp/one.jpg'];
        await care().choosePhotos();
        await settle();
        expect(state().pending, ['/tmp/one.jpg']);
        expect(
          state().error,
          'The photo did not upload. Try again, or remove it.',
        );
      },
    );

    test(
      'a file the API says is not an image is dropped, with its reason',
      () async {
        await open();
        uploader.failures.add(
          const ApiFailure(
            ApiFailureKind.rejected,
            statusCode: 400,
            code: 'INVALID_IMAGE',
            message: 'This file is not an image we can read',
          ),
        );
        picker.next = ['/tmp/notes.txt'];
        await care().choosePhotos();
        await settle();
        expect(state().pending, isEmpty);
        expect(state().error, 'This file is not an image we can read');
        expect(state().busy, isFalse);
      },
    );

    test('the daily limit drops the photos that cannot be sent, with the API’s words', () async {
      await open();
      uploader.failures.add(
        const ApiFailure(
          ApiFailureKind.rejected,
          statusCode: 429,
          code: 'PHOTO_LIMIT',
          message: 'You can add 20 photos to care notes per day.',
        ),
      );
      picker.next = ['/tmp/1.jpg', '/tmp/2.jpg'];
      await care().choosePhotos();
      await settle();
      expect(state().pending, isEmpty);
      expect(state().error, 'You can add 20 photos to care notes per day.');
    });

    test('a photo over 8 MB is not sent, and the next one still is', () async {
      await open();
      sizes['/tmp/huge.jpg'] = 9 * 1024 * 1024;
      picker.next = ['/tmp/huge.jpg', '/tmp/ok.jpg'];
      await care().choosePhotos();
      await settle();
      expect(uploader.sent, ['ok.jpg']);
      expect(state().pending, isEmpty);
      expect(
        state().error,
        'That photo is bigger than 8 MB. Choose a smaller one.',
      );
    });

    test('are removed, sent or waiting', () async {
      await open();
      uploader.failures.add(const ApiFailure(ApiFailureKind.offline));
      picker.next = ['/tmp/a.jpg'];
      await care().choosePhotos();
      await settle();
      care().removePending('/tmp/a.jpg');
      expect(state().pending, isEmpty);
      expect(state().error, isNull);

      picker.next = ['/tmp/b.jpg'];
      await care().choosePhotos();
      await settle();
      expect(state().photos, hasLength(1));
      care().removePhoto(state().photos.single);
      expect(state().photos, isEmpty);
      await settle();
      expect(prefs.getString('care.draft.v1'), isNull);
    });

    test('removing the photo that is on its way stops it and does not report a failure', () async {
      await open();
      uploader.hold = Completer<void>();
      picker.next = ['/tmp/slow.jpg'];
      unawaited(care().choosePhotos());
      await settle();
      expect(state().uploading, isTrue);

      care().removePending('/tmp/slow.jpg');
      uploader.failures.add(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.cancel,
        ),
      );
      uploader.hold!.complete();
      await settle();

      expect(state().uploading, isFalse);
      expect(state().error, isNull);
      expect(state().photos, isEmpty);
      expect(state().pending, isEmpty);
    });

    test(
      'an upload that finishes after the draft was cleared is not kept',
      () async {
        await open();
        uploader.hold = Completer<void>();
        picker.next = ['/tmp/slow.jpg'];
        unawaited(care().choosePhotos());
        await settle();
        care().clear();
        uploader.hold!.complete();
        await settle();
        expect(state().photos, isEmpty);
        expect(state().uploading, isFalse);
      },
    );

    test(
      'taken off the booking when the API refuses them, keeping the note',
      () async {
        await open();
        care().setNote('Silk saree');
        picker.next = ['/tmp/a.jpg'];
        await care().choosePhotos();
        await settle();
        care().photosRefused();
        expect(state().photos, isEmpty);
        expect(state().note, 'Silk saree');
        expect(state().error, contains("couldn't use your photos"));
      },
    );
  });

  group('booking with a care note', () {
    late FakeOrderRepository orders;
    late FakePhotoPicker picker;
    late FakeCareUploader uploader;
    late ProviderContainer container;
    late Schedule schedule;
    final address = testAddress();

    Future<void> open({Map<String, Object> saved = _basketOfShirts}) async {
      orders = FakeOrderRepository();
      picker = FakePhotoPicker();
      uploader = FakeCareUploader();
      container = ProviderContainer(
        overrides: [
          ...await basketOverrides(saved: saved),
          scheduleRepositoryProvider.overrideWithValue(
            FakeScheduleRepository(),
          ),
          orderRepositoryProvider.overrideWithValue(orders),
          addressRepositoryProvider.overrideWithValue(
            FakeAddressRepository([address]),
          ),
          issuePhotoPickerProvider.overrideWithValue(picker),
          carePhotoUploaderProvider.overrideWithValue(uploader),
          carePhotoReaderProvider.overrideWithValue(
            (path) async => Uint8List(1024),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(catalogProvider.future);
      container.read(basketProvider);
      final sub = container.listen(scheduleProvider, (_, _) {});
      addTearDown(sub.close);
      for (
        var i = 0;
        i < 10 &&
            !(container.read(scheduleProvider).value?.isComplete ?? false);
        i++
      ) {
        await Future<void>.delayed(Duration.zero);
      }
      schedule = container.read(scheduleProvider).requireValue;
    }

    CheckoutController checkout() => container.read(checkoutProvider.notifier);
    CareNoteController care() => container.read(careNoteProvider.notifier);
    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('sends the trimmed note and the photos with the order, apart from the pickup note', () async {
      await open();
      container
          .read(checkoutProvider.notifier)
          .setInstructions('Call before arriving');
      care().setNote('  Stain on the collar  ');
      picker.next = ['/tmp/a.jpg', '/tmp/b.jpg'];
      await care().choosePhotos();
      await settle();

      expect(
        await checkout().place(schedule: schedule, address: address),
        isNotNull,
      );
      final dto = orders.placed.single.$1;
      expect(dto.instructions, 'Call before arriving');
      expect(dto.careNote, 'Stain on the collar');
      expect(dto.carePhotoUrls, [
        'https://files.test/care/u1/a.jpg.webp',
        'https://files.test/care/u1/b.jpg.webp',
      ]);
    });

    test('sends nothing extra when there is no care note', () async {
      await open();
      await checkout().place(schedule: schedule, address: address);
      final dto = orders.placed.single.$1;
      expect(dto.careNote, isNull);
      expect(dto.carePhotoUrls, isNull);
      expect(dto.toJson()['careNote'], isNull);
    });

    test('a note of only spaces is no note', () async {
      await open();
      care().setNote('   ');
      await checkout().place(schedule: schedule, address: address);
      expect(orders.placed.single.$1.careNote, isNull);
    });

    test('the draft is gone once the order is placed, and the next booking starts clean', () async {
      await open();
      care().setNote('Stain on the collar');
      await settle();
      await checkout().place(schedule: schedule, address: address);

      expect(container.read(careNoteProvider).note, '');
      expect(
        container.read(sharedPreferencesProvider).getString('care.draft.v1'),
        isNull,
      );
    });

    test('a failed attempt keeps the note and photos, and the retry reuses the key', () async {
      await open();
      care().setNote('Stain on the collar');
      picker.next = ['/tmp/a.jpg'];
      await care().choosePhotos();
      await settle();
      orders.failures.add(const ApiFailure(ApiFailureKind.timeout));

      expect(
        await checkout().place(schedule: schedule, address: address),
        isNull,
      );
      expect(container.read(checkoutProvider).problem, CheckoutProblem.offline);
      expect(container.read(careNoteProvider).note, 'Stain on the collar');
      expect(container.read(careNoteProvider).photos, hasLength(1));

      expect(
        await checkout().place(schedule: schedule, address: address),
        isNotNull,
      );
      expect(orders.placed, hasLength(2));
      expect(
        orders.placed[0].$2,
        orders.placed[1].$2,
        reason: 'the same request is the same order, however often it is sent',
      );
      expect(orders.placed[1].$1.careNote, 'Stain on the collar');
    });

    test(
      'changing the note or the photos is a different request, with a new key',
      () async {
        await open();
        orders.failures.add(const ApiFailure(ApiFailureKind.server));
        care().setNote('Stain on the collar');
        await checkout().place(schedule: schedule, address: address);

        care().setNote('Stain on the sleeve');
        await checkout().place(schedule: schedule, address: address);
        expect(orders.placed[0].$2, isNot(orders.placed[1].$2));
      },
    );

    test('waits for a photo that is still on its way', () async {
      await open();
      uploader.failures.add(const ApiFailure(ApiFailureKind.offline));
      picker.next = ['/tmp/a.jpg'];
      await care().choosePhotos();
      await settle();

      expect(
        await checkout().place(schedule: schedule, address: address),
        isNull,
      );
      expect(orders.placed, isEmpty);

      care().removePending('/tmp/a.jpg');
      expect(
        await checkout().place(schedule: schedule, address: address),
        isNotNull,
      );
      expect(orders.placed.single.$1.carePhotoUrls, isNull);
    });

    test('takes the photos off when the API refuses them, then books with the note alone', () async {
      await open();
      care().setNote('Silk saree');
      picker.next = ['/tmp/a.jpg'];
      await care().choosePhotos();
      await settle();
      orders.failures.add(
        const ApiFailure(
          ApiFailureKind.rejected,
          statusCode: 400,
          code: 'INVALID_PHOTO',
          message: 'Use only photos uploaded from your own account.',
        ),
      );

      expect(
        await checkout().place(schedule: schedule, address: address),
        isNull,
      );
      expect(
        container.read(checkoutProvider).problem,
        CheckoutProblem.photosRefused,
      );
      expect(container.read(careNoteProvider).photos, isEmpty);
      expect(container.read(careNoteProvider).note, 'Silk saree');

      container.read(checkoutProvider.notifier).dismissProblem();
      expect(
        await checkout().place(schedule: schedule, address: address),
        isNotNull,
      );
      final retry = orders.placed.last;
      expect(retry.$1.careNote, 'Silk saree');
      expect(retry.$1.carePhotoUrls, isNull);
      expect(
        retry.$2,
        isNot(orders.placed.first.$2),
        reason: 'the request changed, so it is a new attempt',
      );
    });
  });
}
