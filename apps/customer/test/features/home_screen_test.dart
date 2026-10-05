import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/addresses/address_repository.dart';
import 'package:irondost_customer/features/basket/basket.dart';
import 'package:irondost_customer/features/home/banners.dart';
import 'package:irondost_customer/features/home/home_screen.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/auth/welcome_screen.dart';
import 'package:irondost_customer/design/widgets/service_visual.dart';

import '../helpers.dart';

void main() {
  testWidgets(
    'service categories show distinct bundled 3D artwork without admin images',
    (tester) async {
      await tester.pumpWidget(
        themed(
          Column(
            children: [
              ServiceVisual(category: testCategory('ironing', 'Ironing', [])),
              ServiceVisual(
                category: testCategory('wash-and-iron', 'Wash & iron', []),
              ),
              ServiceVisual(
                category: testCategory('dry-cleaning', 'Dry cleaning', []),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final assets = tester
          .widgetList<Image>(find.byType(Image))
          .map(
            (image) => (image.image as ResizeImage).imageProvider as AssetImage,
          )
          .map((image) => image.assetName);
      expect(assets, [
        'assets/services/ironing-3d.png',
        'assets/services/wash-and-iron-3d.png',
        'assets/services/dry-cleaning-3d.png',
      ]);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Home lists the services before the offers carousel', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390 * 2, 1800 * 2)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final bytes = File('test/fixtures/admin-offer-banner.webp')
        .readAsBytesSync();
    final router = testRouter({
      Routes.home: () => const HomeScreen(),
    }, initial: Routes.home);
    await tester.pumpWidget(
      themedRouter(
        router,
        overrides: [
          ...await basketOverrides(
            banners: [
              const BannerDto(
                id: 'b1',
                imageUrl: 'https://images.example/b1.webp',
                title: 'Festival offer',
                linkUrl: null,
                sortOrder: 0,
                isActive: true,
              ),
            ],
          ),
          addressRepositoryProvider.overrideWithValue(
            FakeAddressRepository([testAddress()]),
          ),
          orderRepositoryProvider.overrideWithValue(FakeOrderRepository()),
          bannerImageProvider.overrideWith((ref, url) => MemoryImage(bytes)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Offers'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Services')).dy,
      lessThan(tester.getTopLeft(find.text('Offers')).dy),
      reason: 'what we sell comes first; the campaign follows',
    );
    expect(
      tester.getTopLeft(find.text('Book a pickup')).dy,
      lessThan(tester.getTopLeft(find.text('Services')).dy),
    );
  });
  group('Repeat last order', () {
    Future<(FakeOrderRepository, ProviderContainer)> open(
      WidgetTester tester,
      List<OrderDto> orders,
    ) async {
      tester.view
        ..physicalSize = const Size(390 * 2, 1800 * 2)
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final repo = FakeOrderRepository()..listed.addAll(orders);
      final router = testRouter({
        Routes.home: () => const HomeScreen(),
        Routes.basket: () => const Text('BASKET PAGE'),
      }, initial: Routes.home);
      await tester.pumpWidget(
        themedRouter(
          router,
          overrides: [
            ...await basketOverrides(),
            addressRepositoryProvider.overrideWithValue(
              FakeAddressRepository([testAddress()]),
            ),
            orderRepositoryProvider.overrideWithValue(repo),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return (
        repo,
        ProviderScope.containerOf(tester.element(find.byType(Scaffold).first)),
      );
    }

    testWidgets(
      'offers the last delivered order when nothing is in progress, and rebuilds the basket',
      (tester) async {
        final (repo, container) = await open(tester, [
          testOrder(id: 'x1', status: OrderStatus.cancelled),
          testOrder(id: 'd1', status: OrderStatus.delivered, pieces: 12),
          testOrder(id: 'd0', status: OrderStatus.delivered, pieces: 3),
        ]);

        expect(
          find.text('Repeat last order · 12 items'),
          findsOneWidget,
          reason: 'the newest delivered order, skipping the cancelled one',
        );
        expect(repo.listAsked, contains((Scope.past, 1)));

        await tester.tap(find.text('Repeat last order · 12 items'));
        await tester.pumpAndSettle();

        expect(find.text('BASKET PAGE'), findsOneWidget);
        expect(container.read(basketProvider).quantityOf('shirt'), 12);
      },
    );

    testWidgets(
      'is not offered while an order is in progress, and past orders are not even loaded',
      (tester) async {
        final (repo, _) = await open(tester, [
          testOrder(id: 'a1'),
          testOrder(id: 'd1', status: OrderStatus.delivered),
        ]);

        expect(find.textContaining('Repeat last order'), findsNothing);
        expect(repo.listAsked, [(Scope.active, 1)]);
      },
    );

    testWidgets('is not offered to someone with no delivered order yet', (
      tester,
    ) async {
      await open(tester, [testOrder(id: 'x1', status: OrderStatus.cancelled)]);
      expect(find.textContaining('Repeat last order'), findsNothing);
    });
  });
  testWidgets(
    'Home shows active orders from the existing provider and opens tracking',
    (tester) async {
      final repo = FakeOrderRepository()
        ..listed.addAll([
          testOrder(
            id: 'first',
            status: OrderStatus.processing,
            deliveryDate: '2099-10-06',
          ),
          testOrder(id: 'second'),
        ]);
      final router = testRouter({
        Routes.home: () => const HomeScreen(),
        Routes.orderDetail: () => const Text('TRACKING'),
      }, initial: Routes.home);
      await tester.pumpWidget(
        themedRouter(
          router,
          overrides: [
            ...await basketOverrides(),
            addressRepositoryProvider.overrideWithValue(
              FakeAddressRepository([testAddress()]),
            ),
            orderRepositoryProvider.overrideWithValue(repo),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Being ironed'), findsOneWidget);
      expect(find.text('View all 2 active orders'), findsOneWidget);
      expect(repo.listAsked, [(Scope.active, 1)]);
      await tester.tap(find.text('Track order'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.order('first'));
      expect(find.text('TRACKING'), findsOneWidget);
    },
  );
  testWidgets('Welcome opens each policy independently before sign-in', (
    tester,
  ) async {
    final router = testRouter({
      Routes.welcome: () => const WelcomeScreen(),
      '/legal/terms': () => const Scaffold(body: Text('TERMS')),
      '/legal/privacy': () => const Scaffold(body: Text('PRIVACY')),
    }, initial: Routes.welcome);
    await tester.pumpWidget(themedRouter(router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terms of service'));
    await tester.pumpAndSettle();
    expect(find.text('TERMS'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy policy'));
    await tester.pumpAndSettle();
    expect(find.text('PRIVACY'), findsOneWidget);
  });
}
