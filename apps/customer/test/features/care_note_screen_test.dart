import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/design/widgets/id_text_field.dart';
import 'package:irondost_customer/design/widgets/phrase_chip.dart';
import 'package:irondost_customer/features/addresses/address_repository.dart';
import 'package:irondost_customer/features/basket/quote.dart';
import 'package:irondost_customer/features/checkout/care_note.dart';
import 'package:irondost_customer/features/checkout/care_note_section.dart';
import 'package:irondost_customer/features/checkout/checkout_screen.dart';
import 'package:irondost_customer/features/issues/issues.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/schedule/schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';
import 'care_note_test.dart' show FakeCareUploader, FakePhotoPicker;

Future<void> settle(WidgetTester tester) async {
  await tester.pump(quoteDebounce + const Duration(milliseconds: 10));
  await tester.pumpAndSettle();
}

List<CatalogCategoryDto> catalogWithDryCleaning() => [
  ...testCatalog(),
  testCategory('dry-cleaning', 'Dry cleaning', [
    testItem('suit', 'Suit', 30000, categoryId: 'dry-cleaning'),
  ], sortOrder: 2),
];

void main() {
  const ironing = {'basket.v1': '{"lines":{"shirt":2},"promoCode":null}'};

  late FakePhotoPicker picker;
  late FakeCareUploader uploader;

  Future<(FakeOrderRepository, ProviderContainer)> pump(
    WidgetTester tester, {
    Map<String, Object> saved = ironing,
    List<CatalogCategoryDto>? catalog,
    double textScale = 1,
    double width = 390,
  }) async {
    tester.view
      ..physicalSize = Size(width * 3, 1300 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    picker = FakePhotoPicker();
    uploader = FakeCareUploader();
    final orders = FakeOrderRepository();
    final router = testRouter({
      '/schedule': () => Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => context.push(Routes.checkout),
              child: const Text('SCHEDULE PAGE'),
            ),
          ),
        ),
      ),
      Routes.checkout: () => const CheckoutScreen(),
      Routes.orderConfirmed: () => const Text('CONFIRMED PAGE'),
      Routes.orderPay: () => const Text('PAY PAGE'),
      Routes.home: () => const Text('HOME PAGE'),
      Routes.book: () => const Text('CATALOGUE PAGE'),
    }, initial: '/schedule');
    await tester.pumpWidget(
      themedRouter(
        router,
        textScale: textScale,
        overrides: [
          ...await basketOverrides(saved: saved, catalog: catalog),
          scheduleRepositoryProvider.overrideWithValue(
            FakeScheduleRepository(),
          ),
          orderRepositoryProvider.overrideWithValue(orders),
          addressRepositoryProvider.overrideWithValue(
            FakeAddressRepository([testAddress()]),
          ),
          issuePhotoPickerProvider.overrideWithValue(picker),
          carePhotoUploaderProvider.overrideWithValue(uploader),
          carePhotoReaderProvider.overrideWithValue(
            (path) async => Uint8List(1024),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    unawaited(router.push(Routes.checkout));
    await tester.pumpAndSettle();
    await settle(tester);
    return (orders, container);
  }

  final careField = find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is IdTextField && w.label == 'Care note',
    ),
    matching: find.byType(TextField),
  );

  Future<void> show(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, List<String> paths) async {
    picker.next = paths;
    await show(tester, find.text('Add photos'));
    await tester.tap(find.text('Add photos'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'asks about the clothes between the review rows and the pickup note, and says what it is for',
    (tester) async {
      await pump(tester);

      final header = find.text('Anything we should know about your clothes?');
      await show(tester, header);
      expect(header, findsOneWidget);
      expect(
        find.text('Care note'),
        findsOneWidget,
        reason: 'the label sits above the field',
      );
      expect(find.text('Photos (optional, up to 3)'), findsOneWidget);
      expect(find.text('Add photos'), findsOneWidget);
      expect(
        find.text('We will try to remove stains but cannot promise it.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('The pickup note below is for your pickup partner'),
        findsOneWidget,
      );

      final order = [
        find.text('Delivery'),
        header,
        find.text('Note for your pickup (optional)'),
      ].map((f) => tester.getTopLeft(f.first).dy).toList();
      expect(order[0], lessThan(order[1]), reason: 'after the review rows');
      expect(order[1], lessThan(order[2]), reason: 'before the pickup note');
    },
  );

  group('prompts', () {
    testWidgets('an ironing basket gets the ironing prompts only', (
      tester,
    ) async {
      await pump(tester);
      await show(tester, find.text('Starch'));
      expect(find.text('Starch'), findsOneWidget);
      expect(find.text('Fold, do not hang'), findsOneWidget);
      for (final other in [
        'Stain on a garment',
        'Colours may run',
        'Wash separately',
      ]) {
        expect(find.text(other), findsNothing, reason: other);
      }
    });

    testWidgets(
      'dry cleaning and washing together get both sets, colours once',
      (tester) async {
        await pump(
          tester,
          saved: {
            'basket.v1': '{"lines":{"suit":1,"wash-shirt":2},"promoCode":null}',
          },
          catalog: catalogWithDryCleaning(),
        );
        await show(tester, find.text('Stain on a garment'));
        for (final phrase in [
          'Stain on a garment',
          'Delicate fabric',
          'Embroidery or beadwork',
          'Colours may run',
          'Wash separately',
          'Heavily soiled',
        ]) {
          expect(find.text(phrase), findsOneWidget, reason: phrase);
        }
        expect(find.text('Colour may run'), findsNothing);
        expect(find.text('Starch'), findsNothing);
      },
    );

    testWidgets('a prompt is added to the note once, and shows as chosen', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final (_, container) = await pump(tester);
      await show(tester, find.text('Starch'));

      final starch = find.widgetWithText(PhraseChip, 'Starch');
      await tester.tap(starch);
      await tester.pump();
      await tester.tap(starch);
      await tester.pump();
      await tester.tap(find.widgetWithText(PhraseChip, 'Fold, do not hang'));
      await tester.pump();

      expect(
        container.read(careNoteProvider).note,
        'Starch. Fold, do not hang',
      );
      expect(find.text('Starch. Fold, do not hang'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel('Add "Starch" to the care note'),
            )
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel('Add "Fold, do not hang" to the care note'),
            )
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      semantics.dispose();
    });

    testWidgets('are full-size touch targets', (tester) async {
      await pump(tester);
      await show(tester, find.text('Starch'));
      for (final phrase in ['Starch', 'Fold, do not hang']) {
        final target = find
            .ancestor(of: find.text(phrase), matching: find.byType(InkWell))
            .first;
        expect(
          tester.getSize(target).height,
          greaterThanOrEqualTo(48),
          reason: phrase,
        );
      }
    });
  });

  group('the note', () {
    testWidgets('stops at 500 characters', (tester) async {
      final (_, container) = await pump(tester);
      await show(tester, find.text('Care note'));
      await tester.enterText(careField, 'a' * 600);
      await tester.pump();
      expect(container.read(careNoteProvider).note.length, careNoteMaxLength);
    });

    testWidgets('is sent with the order, apart from the pickup note', (
      tester,
    ) async {
      final (orders, _) = await pump(tester);
      await show(tester, find.text('Care note'));
      await tester.enterText(
        careField,
        '  Stain on the collar of the white shirt  ',
      );
      await tester.pump();
      await tester.tap(find.text('Pay ₹30'));
      await settle(tester);

      final dto = orders.placed.single.$1;
      expect(dto.careNote, 'Stain on the collar of the white shirt');
      expect(dto.carePhotoUrls, isNull);
      expect(dto.instructions, isNull);
    });

    testWidgets('is optional: nothing is sent when it is left empty', (
      tester,
    ) async {
      final (orders, _) = await pump(tester);
      await tester.tap(find.text('Pay ₹30'));
      await settle(tester);
      expect(orders.placed.single.$1.careNote, isNull);
      expect(orders.placed.single.$1.carePhotoUrls, isNull);
    });

    testWidgets(
      'is kept as a draft and comes back, until the order is placed',
      (tester) async {
        await pump(
          tester,
          saved: {
            ...ironing,
            'care.draft.v1': jsonEncode({
              'note': 'Silk saree: stain on the pallu',
              'photos': ['https://files.test/care/u1/a.webp'],
              'pending': [],
            }),
          },
        );
        await show(tester, find.text('Care note'));
        expect(find.text('Silk saree: stain on the pallu'), findsOneWidget);
        expect(find.byTooltip('Remove Photo 1'), findsOneWidget);

        await tester.tap(find.text('Pay ₹30'));
        await settle(tester);
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('care.draft.v1'),
          isNull,
          reason: 'placed: the draft is gone',
        );
      },
    );

    testWidgets('the field starts over once the order is placed', (
      tester,
    ) async {
      final (_, container) = await pump(tester);
      await show(tester, find.text('Care note'));
      await tester.enterText(careField, 'Stain on the collar');
      await tester.pump();
      container.read(careNoteProvider.notifier).clear();
      await tester.pump();
      expect(tester.widget<TextField>(careField).controller!.text, '');
    });
  });

  group('photos', () {
    testWidgets('are added with thumbnails and sent with the order', (
      tester,
    ) async {
      final (orders, _) = await pump(tester);
      await choose(tester, ['/tmp/a.jpg', '/tmp/b.jpg']);

      expect(find.byTooltip('Remove Photo 1'), findsOneWidget);
      expect(find.byTooltip('Remove Photo 2'), findsOneWidget);
      expect(find.text('Add more photos'), findsOneWidget);

      await tester.tap(find.text('Pay ₹30'));
      await settle(tester);
      expect(orders.placed.single.$1.carePhotoUrls, [
        'https://files.test/care/u1/a.jpg.webp',
        'https://files.test/care/u1/b.jpg.webp',
      ]);
    });

    testWidgets('stop at three: nothing more to add', (tester) async {
      await pump(tester);
      await choose(tester, [
        '/tmp/a.jpg',
        '/tmp/b.jpg',
        '/tmp/c.jpg',
        '/tmp/d.jpg',
      ]);
      expect(find.byTooltip('Remove Photo 3'), findsOneWidget);
      expect(find.byTooltip('Remove Photo 4'), findsNothing);
      expect(find.text('Add photos'), findsNothing);
      expect(find.text('Add more photos'), findsNothing);
      expect(picker.asked, [3]);
    });

    testWidgets('can be removed again', (tester) async {
      final (orders, _) = await pump(tester);
      await choose(tester, ['/tmp/a.jpg', '/tmp/b.jpg']);
      await tester.tap(find.byTooltip('Remove Photo 1'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove Photo 2'), findsNothing);
      await tester.tap(find.text('Pay ₹30'));
      await settle(tester);
      expect(orders.placed.single.$1.carePhotoUrls, [
        'https://files.test/care/u1/b.jpg.webp',
      ]);
    });

    testWidgets('remove buttons are full-size touch targets', (tester) async {
      await pump(tester);
      await choose(tester, ['/tmp/a.jpg']);
      final size = tester.getSize(
        find
            .ancestor(
              of: find.byTooltip('Remove Photo 1'),
              matching: find.byType(IconButton),
            )
            .first,
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets(
      'one that did not send is kept: booking waits, and the customer can retry or remove it',
      (tester) async {
        final (orders, _) = await pump(tester);
        uploader.failures.add(const ApiFailure(ApiFailureKind.offline));
        await choose(tester, ['/tmp/a.jpg']);

        expect(
          find.textContaining("You're offline. Your photo is kept here"),
          findsOneWidget,
        );
        expect(
          find.text('Upload or remove this photo to book.'),
          findsOneWidget,
        );
        expect(find.text('Try the upload again'), findsOneWidget);
        final pay = find.widgetWithText(FilledButton, 'Pay ₹30');
        expect(
          tester.widget<FilledButton>(pay).onPressed,
          isNull,
          reason: 'the photo would be left off the order',
        );

        await tester.tap(find.text('Try the upload again'));
        await tester.pumpAndSettle();
        expect(find.text('Upload or remove this photo to book.'), findsNothing);
        expect(find.textContaining("You're offline"), findsNothing);
        expect(tester.widget<FilledButton>(pay).onPressed, isNotNull);

        await tester.tap(find.text('Pay ₹30'));
        await settle(tester);
        expect(orders.placed.single.$1.carePhotoUrls, hasLength(1));
      },
    );

    testWidgets(
      'one that is removed after a failure lets booking go ahead without it',
      (tester) async {
        final (orders, _) = await pump(tester);
        uploader.failures.add(
          const ApiFailure(ApiFailureKind.server, statusCode: 500),
        );
        await choose(tester, ['/tmp/a.jpg']);
        expect(
          find.text('The photo did not upload. Try again, or remove it.'),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('Remove Photo 1, not sent yet'));
        await tester.pumpAndSettle();
        expect(find.text('Upload or remove this photo to book.'), findsNothing);

        await tester.tap(find.text('Pay ₹30'));
        await settle(tester);
        expect(orders.placed.single.$1.carePhotoUrls, isNull);
      },
    );

    testWidgets(
      'a refused photo is taken off the booking, with a clear reason',
      (tester) async {
        final (orders, container) = await pump(tester);
        await choose(tester, ['/tmp/a.jpg']);
        orders.failures.add(
          const ApiFailure(
            ApiFailureKind.rejected,
            statusCode: 400,
            code: 'INVALID_PHOTO',
            message: 'Use only photos uploaded from your own account.',
          ),
        );

        await tester.tap(find.text('Pay ₹30'));
        await settle(tester);

        expect(find.text("We couldn't use your photos"), findsOneWidget);
        expect(
          find.textContaining('You have not been charged'),
          findsOneWidget,
        );
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(container.read(careNoteProvider).photos, isEmpty);
        await show(tester, find.text('Care note'));
        expect(find.byTooltip('Remove Photo 1'), findsNothing);
      },
    );
  });

  group('large text and narrow screens', () {
    // The section on its own: the rest of the checkout screen has its own large-text checks.
    for (final (width, scale) in [(320.0, 2.0), (390.0, 2.0), (430.0, 1.0)]) {
      testWidgets(
        'the whole section fits at ${width.round()} dp and ${(scale * 100).round()}% text',
        (tester) async {
          tester.view
            ..physicalSize = Size(width * 3, 1300 * 3)
            ..devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            themed(
              Scaffold(
                body: ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [CareNoteSection()],
                ),
              ),
              textScale: scale,
              overrides: [
                ...await basketOverrides(
                  saved: {
                    'basket.v1':
                        '{"lines":{"wash-shirt":2,"shirt":1},"promoCode":null}',
                    'care.draft.v1': jsonEncode({
                      'note': 'Red silk saree, stain on the sleeve',
                      'photos': [
                        'https://files.test/a.webp',
                        'https://files.test/b.webp',
                        'https://files.test/c.webp',
                      ],
                      'pending': [],
                    }),
                  },
                ),
                issuePhotoPickerProvider.overrideWithValue(FakePhotoPicker()),
                carePhotoUploaderProvider.overrideWithValue(FakeCareUploader()),
              ],
            ),
          );
          await tester.pumpAndSettle();
          await show(
            tester,
            find.text('We will try to remove stains but cannot promise it.'),
          );
          final problem = tester.takeException();
          expect(
            problem,
            isNull,
            reason: problem is FlutterError
                ? problem.toStringDeep()
                : '$problem',
          );
          expect(find.byTooltip('Remove Photo 3'), findsOneWidget);
          expect(find.text('Wash separately'), findsOneWidget);
        },
      );
    }

    testWidgets(
      'with a photo waiting to be sent, and an error, at 320 dp and 200% text',
      (tester) async {
        tester.view
          ..physicalSize = const Size(320 * 3, 1300 * 3)
          ..devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final uploader = FakeCareUploader()
          ..failures.add(const ApiFailure(ApiFailureKind.offline));
        final picker = FakePhotoPicker()..next = ['/tmp/a.jpg'];
        await tester.pumpWidget(
          themed(
            Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: const [CareNoteSection()],
              ),
            ),
            textScale: 2,
            overrides: [
              ...await basketOverrides(saved: ironing),
              issuePhotoPickerProvider.overrideWithValue(picker),
              carePhotoUploaderProvider.overrideWithValue(uploader),
              carePhotoReaderProvider.overrideWithValue(
                (path) async => Uint8List(1024),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        await show(tester, find.text('Add photos'));
        await tester.tap(find.text('Add photos'));
        await tester.pumpAndSettle();
        await show(tester, find.text('Upload or remove this photo to book.'));
        expect(find.text('Try the upload again'), findsOneWidget);
        final problem = tester.takeException();
        expect(
          problem,
          isNull,
          reason: problem is FlutterError ? problem.toStringDeep() : '$problem',
        );
      },
    );
  });
}
