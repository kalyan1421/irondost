import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/home/banners.dart';
import 'package:irondost_customer/features/addresses/address_repository.dart';
import 'package:irondost_customer/features/addresses/addresses_controller.dart';
import 'package:irondost_customer/features/auth/session.dart';
import 'package:irondost_customer/features/home/offer_banners.dart';
import 'package:irondost_customer/features/offers/promotions.dart';

import '../helpers.dart';

BannerDto banner(
  String id,
  String title, {
  int order = 0,
  bool active = true,
  String? link,
}) => BannerDto(
  id: id,
  imageUrl: 'https://images.example/$id.webp',
  title: title,
  linkUrl: link,
  sortOrder: order,
  isActive: active,
);

void main() {
  test('scheduled campaign artwork precedes standalone banners and duplicate images appear once', () async {
    final promo = testPromo('DASARA15', 'Dasara: 15% off');
    final configured = PromotionDto.fromJson({
      ...promo.toJson(),
      'discountType': promo.discountType.toJson(),
      'imageUrl': 'https://images.example/shared.webp',
    });
    final container = ProviderContainer(
      overrides: [
        promotionsProvider.overrideWith((ref) async => [configured]),
        bannersProvider.overrideWith(
          (ref) async => [
            banner('shared', 'Duplicate'),
            banner('other', 'Standalone'),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(promotionsProvider.future);
    await container.read(bannersProvider.future);
    final result = container.read(homeOfferBannersProvider);
    expect(result.map((b) => b.id), ['promotion:${configured.id}', 'other']);
  });
  test('active promotion artwork joins the carousel with readable terms and an Offers link', () {
    final promo = testPromo(
      'DASARA15',
      'Dasara: 15% off',
      minOrderPaise: 10000,
      maxDiscountPaise: 10000,
    );
    final configured = PromotionDto.fromJson({
      ...promo.toJson(),
      'discountType': promo.discountType.toJson(),
      'imageUrl': 'https://images.example/dasara.png',
    });
    final results = promotionBanners([promo, configured]);
    expect(results, hasLength(1));
    expect(results.single.imageUrl, configured.imageUrl);
    expect(results.single.title, contains('Min. order ₹100'));
    expect(results.single.title, contains('Up to ₹100'));
    expect(results.single.linkUrl, Routes.offers);
    expect(
      promotionBanners([
        PromotionDto.fromJson({
          ...configured.toJson(),
          'discountType': configured.discountType.toJson(),
          'isActive': false,
        }),
      ]),
      isEmpty,
    );
  });
  test('admin active banner endpoint is used and inactive content is excluded in sort order', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example'));
    String? requested;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requested = options.path;
          handler.resolve(
            Response(
              requestOptions: options,
              data: [
                banner('b', 'Second', order: 2).toJson(),
                banner('hidden', 'Inactive', active: false).toJson(),
                banner('a', 'First', order: 1).toJson(),
              ],
            ),
          );
        },
      ),
    );
    final container = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);
    final results = await container.read(bannersProvider.future);
    expect(requested, '/v1/banners');
    expect(results.map((b) => b.id), ['a', 'b']);
  });

  test('admin links resolve customer pages and exclude payment or unknown destinations', () {
    expect(bannerAppRoute('irondost://offers'), Routes.offers);
    expect(
      bannerAppRoute('irondost:///book?service=wash-and-iron'),
      '/book?service=wash-and-iron',
    );
    expect(bannerAppRoute('/offers'), Routes.offers);
    expect(bannerAppRoute('irondost://orders/order-id'), '/order/order-id');
    expect(bannerAppRoute('https://example.com/offer'), isNull);
    expect(bannerAppRoute('javascript:alert(1)'), isNull);
    expect(bannerAppRoute('//example.com/offers'), isNull);
    expect(bannerAppRoute('/order/order-id/pay'), isNull);
    expect(bannerAppRoute('/unknown'), isNull);
  });

  Future<void> open(WidgetTester tester, List<BannerDto> list) async {
    await tester.pumpWidget(const SizedBox());
    tester.view
      ..physicalSize = const Size(390 * 2, 844 * 2)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final bytes = File('test/fixtures/admin-offer-banner.webp')
        .readAsBytesSync();
    final router = testRouter({
      Routes.home: () => const Scaffold(
        body: Padding(padding: EdgeInsets.all(20), child: OfferBanners()),
      ),
      Routes.offers: () => const Scaffold(body: Text('ALL OFFERS')),
    }, initial: Routes.home);
    await tester.pumpWidget(
      themedRouter(
        router,
        overrides: [
          promotionsProvider.overrideWith((ref) async => const []),
          bannersProvider.overrideWith((ref) async => list),
          bannerImageProvider.overrideWith((ref, url) => MemoryImage(bytes)),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'campaign removal and reordering reset image, caption, link and page together',
    (tester) async {
      final list = [
        banner('a', 'First campaign'),
        banner('b', 'Second campaign'),
      ];
      await open(tester, list);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(OfferBanners)),
      );
      await tester.tap(find.byTooltip('Next offer'));
      await tester.pumpAndSettle();
      expect(find.text('Second campaign'), findsOneWidget);
      list
        ..clear()
        ..add(banner('new', 'Replacement campaign', link: '/offers'));
      container.invalidate(bannersProvider);
      await tester.pumpAndSettle();
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        0,
      );
      expect(find.text('Replacement campaign'), findsOneWidget);
      expect(find.text('Second campaign'), findsNothing);
      expect(find.byTooltip('Next offer'), findsNothing);
      await tester.tap(find.text('View offer'));
      await tester.pumpAndSettle();
      expect(find.text('ALL OFFERS'), findsOneWidget);
    },
  );

  for (final hasAddress in [false, true]) {
    testWidgets(
      'booking campaign keeps the address gate, address present: $hasAddress',
      (tester) async {
        final router = testRouter({
          Routes.home: () => const Scaffold(body: OfferBanners()),
          Routes.addressPin: () => const Scaffold(body: Text('ADD ADDRESS')),
          Routes.book: () => const Scaffold(body: Text('BOOK')),
        }, initial: Routes.home);
        await tester.pumpWidget(
          themedRouter(
            router,
            overrides: [
              ...await basketOverrides(
                banners: [
                  banner(
                    'book',
                    'Book wash & iron',
                    link: 'irondost://book?service=wash-and-iron',
                  ),
                ],
              ),
              addressRepositoryProvider.overrideWithValue(
                FakeAddressRepository(hasAddress ? [testAddress()] : []),
              ),
              bannerImageProvider.overrideWith(
                (ref, url) => MemoryImage(
                  File('test/fixtures/admin-offer-banner.webp')
                      .readAsBytesSync(),
                ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(OfferBanners)),
        );
        await container.read(sessionProvider.future);
        await container.read(addressesProvider.future);
        await tester.pump();
        await tester.tap(find.text('View offer'));
        await tester.pumpAndSettle();
        expect(
          router.state.matchedLocation,
          hasAddress ? Routes.book : Routes.addressPin,
        );
        if (hasAddress) {
          expect(router.state.uri.queryParameters['service'], 'wash-and-iron');
        }
      },
    );
  }

  testWidgets(
    'manual next/previous controls show each admin image and title without automatic rotation',
    (tester) async {
      await open(tester, [
        banner('a', 'First campaign'),
        banner('b', 'Second campaign'),
      ]);
      expect(find.text('First campaign'), findsOneWidget);
      expect(find.text('1 of 2'), findsOneWidget);
      expect(
        tester.widget<Image>(find.byType(Image).first).image,
        isA<MemoryImage>(),
      );
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('1 of 2'), findsOneWidget);
      await tester.tap(find.byTooltip('Next offer'));
      await tester.pumpAndSettle();
      expect(find.text('Second campaign'), findsOneWidget);
      expect(find.text('2 of 2'), findsOneWidget);
      await tester.tap(find.byTooltip('Previous offer'));
      await tester.pumpAndSettle();
      expect(find.text('First campaign'), findsOneWidget);
    },
  );

  testWidgets(
    'an admin deep link opens Offers and an image without a link has no fake action',
    (tester) async {
      await open(tester, [
        banner('a', 'View current offer', link: 'irondost://offers'),
      ]);
      await tester.tap(find.text('View offer'));
      await tester.pumpAndSettle();
      expect(find.text('ALL OFFERS'), findsOneWidget);
      await open(tester, [banner('b', 'An announcement')]);
      expect(find.text('View offer'), findsNothing);
      expect(find.byTooltip('Next offer'), findsNothing);
    },
  );

  testWidgets('no admin banners leaves no empty campaign region', (
    tester,
  ) async {
    await open(tester, []);
    expect(find.text('Offers'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });
}
