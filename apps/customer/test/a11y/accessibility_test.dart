
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/account/account_screen.dart';
import 'package:irondost_customer/features/account/edit_profile_screen.dart';
import 'package:irondost_customer/features/account/help_screen.dart';
import 'package:irondost_customer/features/account/legal_content.dart';
import 'package:irondost_customer/features/account/legal_screen.dart';
import 'package:irondost_customer/features/account/account_repository.dart';
import 'package:irondost_customer/features/addresses/address_repository.dart';
import 'package:irondost_customer/features/addresses/addresses_screen.dart';
import 'package:irondost_customer/features/auth/auth_repository.dart';
import 'package:irondost_customer/features/auth/name_screen.dart';
import 'package:irondost_customer/features/auth/phone_screen.dart';
import 'package:irondost_customer/features/auth/session.dart';
import 'package:irondost_customer/features/auth/welcome_screen.dart';
import 'package:irondost_customer/features/basket/basket_screen.dart';
import 'package:irondost_customer/features/catalogue/catalogue_screen.dart';
import 'package:irondost_customer/features/basket/quote.dart';
import 'package:irondost_customer/features/home/home_screen.dart';
import 'package:irondost_customer/features/notifications/notifications.dart';
import 'package:irondost_customer/features/notifications/notifications_screen.dart';
import 'package:irondost_customer/features/offers/offers_screen.dart';
import 'package:irondost_customer/features/offers/promotions.dart';
import 'package:irondost_customer/features/orders/order_detail_screen.dart';
import 'package:irondost_customer/features/orders/order_repository.dart';
import 'package:irondost_customer/features/orders/orders_screen.dart';
import 'package:irondost_customer/features/schedule/schedule.dart';
import 'package:irondost_customer/features/schedule/schedule_screen.dart';
import 'package:irondost_customer/features/shell/offline_banner.dart';
import 'package:irondost_customer/features/startup/startup.dart';
import 'package:irondost_customer/data/reachability.dart';

import '../helpers.dart';

/// Every screen a customer reaches, drawn in light and dark, at normal and at 200% text size.
///
/// At 200% nothing may overflow (Flutter reports an overflow as an error, which fails the test). At normal
/// size every tap target must be big enough and labelled, and all text must contrast with what is behind it.
void main() {
  const config = PublicConfigDto(
    appName: 'IronDost',
    supportPhone: '+919063290012',
    supportEmail: 'help@irondost.test',
    minOrderPaise: 0,
    deliveryFeePaise: 0,
    freeDeliveryAbovePaise: null,
    minTurnaroundHours: 20,
    maxAdvanceDays: 30,
    slots: [],
  );
  final startup = startupProvider.overrideWith((ref) async => const Startup(config: config, installedVersion: '2.0.0'));
  final now = DateTime.now();
  final today = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)).toIso8601String().substring(0, 10);

  /// Puts [screen] at [path] in a router, with a page behind it to go back to.
  GoRouter at(String path, Widget screen) => GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SizedBox()),
          GoRoute(path: path, builder: (_, _) => screen),
        ],
      )..push(path);

  final scenarios = <String, Future<Widget> Function(Brightness b, double scale)>{
    'Home': (b, s) async => themed(
          const HomeScreen(),
          overrides: [
            ...await basketOverrides(promotions: [testPromo('WELCOME20', '20% off your first order', minOrderPaise: 29900, maxDiscountPaise: 10000, limit: 1)]),
            addressRepositoryProvider.overrideWithValue(FakeAddressRepository([testAddress()])),
            notificationRepositoryProvider.overrideWithValue(FakeNotificationRepository()..inbox.add(testNotification('n1'))),
          ],
          brightness: b,
          textScale: s,
        ),
    'Offline banner': (b, s) async => themed(
          const Scaffold(body: Align(alignment: Alignment.bottomCenter, child: OfflineBanner())),
          overrides: [reachabilityProvider.overrideWith(_Offline.new)],
          brightness: b,
          textScale: s,
        ),
    'Name': (b, s) async => themed(const NameScreen(), overrides: [sessionProvider.overrideWith(SignedInSession.new)], brightness: b, textScale: s),
    'Catalogue': (b, s) async => themed(
          const CatalogueScreen(),
          overrides: await basketOverrides(saved: {'basket.v1': '{"lines":{"shirt":2,"saree":1},"promoCode":null}'}),
          brightness: b,
          textScale: s,
        ),
    'Addresses': (b, s) async => themedRouter(
          at(Routes.addresses, const AddressesScreen()),
          overrides: [addressRepositoryProvider.overrideWithValue(FakeAddressRepository([testAddress(), testAddress(id: 'a2', label: 'Work', isPrimary: false), testAddress(id: 'a3', label: 'Parents', isPrimary: false, serviceable: false)]))],
          brightness: b,
          textScale: s,
        ),
    'Welcome': (b, s) async => themedRouter(testRouter({Routes.welcome: () => const WelcomeScreen()}, initial: Routes.welcome), brightness: b, textScale: s),
    'Phone': (b, s) async => themed(const PhoneScreen(), overrides: [authRepositoryProvider.overrideWithValue(FakeAuth())], brightness: b, textScale: s),
    'Basket': (b, s) async => themed(
          const BasketScreen(),
          overrides: await basketOverrides(saved: {'basket.v1': '{"lines":{"shirt":10,"trousers":4,"saree":1},"promoCode":null}'}),
          brightness: b,
          textScale: s,
        ),
    'Orders': (b, s) async => themedRouter(
          testRouter({Routes.orders: () => const OrdersScreen()}, initial: Routes.orders),
          overrides: [
            orderRepositoryProvider.overrideWithValue(
              FakeOrderRepository()
                ..listed.addAll([
                  testOrder(id: 'a1', number: 'ID001046', method: PaymentMethod.online, paymentStatus: PaymentStatus.paid, paidPaise: 24800, pickupDate: today),
                  testOrder(id: 'a2', number: 'ID001042', status: OrderStatus.processing, totalPaise: 18000, pickedUpAt: DateTime.utc(2026, 10, 1, 12, 10), pieces: 12),
                ]),
            ),
            sessionProvider.overrideWith(SignedInSession.new),
          ],
          brightness: b,
          textScale: s,
        ),
    'Order detail': (b, s) async {
      final order = testOrder(id: 'a2', number: 'ID001042', status: OrderStatus.processing, totalPaise: 18000, pickedUpAt: DateTime.utc(2026, 10, 1, 12, 10), pieces: 12);
      return themedRouter(
        at(Routes.order('a2'), OrderDetailScreen(orderId: 'a2', initial: order)),
        overrides: [orderRepositoryProvider.overrideWithValue(FakeOrderRepository()..orders['a2'] = order), ...await basketOverrides()],
        brightness: b,
        textScale: s,
      );
    },
    'Offers': (b, s) async => themed(
          const OffersScreen(),
          overrides: [
            promotionsProvider.overrideWith(
              (ref) async => [
                testPromo('WELCOME20', '20% off your first order', minOrderPaise: 29900, maxDiscountPaise: 10000, limit: 1),
                testPromo('FRESH15', '15% off orders above ₹500', value: 15, minOrderPaise: 50000, maxDiscountPaise: 15000, description: 'On any service.'),
                testPromo('FLAT50', '₹50 off orders above ₹400', type: DiscountType.flat, value: 5000, minOrderPaise: 40000, limit: 2),
              ],
            ),
          ],
          brightness: b,
          textScale: s,
        ),
    'Offers (empty)': (b, s) async => themed(const OffersScreen(), overrides: [promotionsProvider.overrideWith((ref) async => [])], brightness: b, textScale: s),
    'Offers (offline)': (b, s) async => themed(
          const OffersScreen(),
          overrides: [promotionsProvider.overrideWith((ref) async => throw const ApiFailure(ApiFailureKind.offline))],
          brightness: b,
          textScale: s,
        ),
    'Notifications': (b, s) async => themedRouter(
          testRouter({Routes.notifications: () => const NotificationsScreen()}, initial: Routes.notifications),
          overrides: [
            notificationRepositoryProvider.overrideWithValue(
              FakeNotificationRepository()
                ..inbox.addAll([
                  testNotification('n1', title: 'Partner on the way', createdAt: now),
                  testNotification('n2', type: 'payment_received', title: 'Payment received', body: '₹248 received for order ID001046.', createdAt: now, readAt: now),
                  testNotification('n3', title: 'We have your clothes', createdAt: now.subtract(const Duration(days: 3)), readAt: now),
                ]),
            ),
            sessionProvider.overrideWith(SignedInSession.new),
          ],
          brightness: b,
          textScale: s,
        ),
    'Schedule': (b, s) async => themed(
          const ScheduleScreen(),
          overrides: [scheduleRepositoryProvider.overrideWithValue(FakeScheduleRepository()), startup, ...await basketOverrides()],
          brightness: b,
          textScale: s,
        ),
    'Account': (b, s) async => themedRouter(
          testRouter({Routes.account: () => const AccountScreen()}, initial: Routes.account),
          overrides: [
            sessionProvider.overrideWith(SignedInSession.new),
            addressRepositoryProvider.overrideWithValue(FakeAddressRepository([testAddress(), testAddress(id: 'a2', label: 'Work', isPrimary: false)])),
            notificationRepositoryProvider.overrideWithValue(FakeNotificationRepository()..inbox.add(testNotification('n1'))),
            startup,
          ],
          brightness: b,
          textScale: s,
        ),
    'Edit profile': (b, s) async => themedRouter(at(Routes.editProfile, const EditProfileScreen()), overrides: [sessionProvider.overrideWith(SignedInSession.new)], brightness: b, textScale: s),
    'Help': (b, s) async => themedRouter(at(Routes.help, const HelpScreen()), overrides: [startup], brightness: b, textScale: s),
    for (final doc in LegalDoc.values) 'Legal: ${doc.slug}': (b, s) async => themedRouter(at(Routes.legal(doc.slug), LegalScreen(doc: doc)), brightness: b, textScale: s),
  };

  /// Sheets that open from the Account tab: each is the Account screen plus what to tap to open it.
  const accountSheets = {'Log out sheet': 'Log out', 'Delete account sheet': 'Delete account', 'Delete blocked sheet': 'Delete account'};

  Future<void> show(WidgetTester tester, Widget app) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    // Some screens hold a spinner or a debounce timer; a few frames is enough to be fully drawn.
    await tester.pump(quoteDebounce + const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  for (final MapEntry(key: name, value: build) in scenarios.entries) {
    group(name, () {
      for (final brightness in Brightness.values) {
        testWidgets('${brightness.name}: tap targets, labels and contrast', (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await show(tester, await build(brightness, 1));
            await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
            await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
            await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          } finally {
            semantics.dispose();
          }
        });

        testWidgets('${brightness.name}: fits at 200% text', (tester) async {
          // Collect every error rather than stopping at the first, so one run shows all that need fixing.
          final problems = <String>[];
          final original = FlutterError.onError;
          FlutterError.onError = (details) {
            final lines = details.toString().split('\n');
            final what = lines.firstWhere((l) => l.contains('overflowed'), orElse: () => lines.first);
            final where = lines.firstWhere((l) => l.contains('/lib/'), orElse: () => '');
            problems.add('$what ${where.trim()}');
          };
          try {
            await show(tester, await build(brightness, 2));
          } finally {
            FlutterError.onError = original;
          }
          expect(problems.toSet().toList(), isEmpty);
        });
      }
    });
  }

  group('Account sheets', () {
    Future<Widget> account(Brightness b, double scale, FakeAccountRepository repo) async => themedRouter(
          testRouter({Routes.account: () => const AccountScreen()}, initial: Routes.account),
          overrides: [
            sessionProvider.overrideWith(SignedInSession.new),
            accountRepositoryProvider.overrideWithValue(repo),
            addressRepositoryProvider.overrideWithValue(FakeAddressRepository([testAddress()])),
            notificationRepositoryProvider.overrideWithValue(FakeNotificationRepository()),
            startup,
          ],
          brightness: b,
          textScale: scale,
        );

    Future<void> open(WidgetTester tester, String row, {bool blocked = false}) async {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.scrollUntilVisible(find.text(row), 300, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.text(row));
      await tester.pump();
      await tester.tap(find.text(row));
      await tester.pump(const Duration(milliseconds: 500));
      if (blocked) {
        final delete = find.widgetWithText(FilledButton, 'Delete account');
        await tester.ensureVisible(delete);
        await tester.pumpAndSettle();
        await tester.tap(delete, warnIfMissed: true);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        expect(find.text('Finish your orders first'), findsOneWidget);
      }
    }

    for (final MapEntry(key: name, value: row) in accountSheets.entries) {
      for (final brightness in Brightness.values) {
        final blocked = name.contains('blocked');
        FakeAccountRepository repo() => FakeAccountRepository()..failure = blocked ? const ApiFailure(ApiFailureKind.rejected, statusCode: 409, code: 'ACTIVE_ORDERS', details: {'activeOrders': 2}) : null;

        testWidgets('$name, ${brightness.name}: tap targets, labels and contrast', (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await show(tester, await account(brightness, 1, repo()));
            await open(tester, row, blocked: blocked);
            await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
            await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
            await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          } finally {
            semantics.dispose();
          }
        });

        testWidgets('$name, ${brightness.name}: fits at 200% text', (tester) async {
          final problems = <String>[];
          final original = FlutterError.onError;
          FlutterError.onError = (details) => problems.add(details.toString().split('\n').first);
          try {
            await show(tester, await account(brightness, 2, repo()));
            await open(tester, row, blocked: blocked);
          } finally {
            FlutterError.onError = original;
          }
          expect(problems.toSet().toList(), isEmpty);
        });
      }
    }
  });
}

/// Starts with the API unreachable, so the banner is showing.
class _Offline extends Reachability {
  @override
  bool build() => false;
}
