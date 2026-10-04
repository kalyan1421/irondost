import 'package:irondost_customer/features/orders/pay_due.dart';
import 'package:irondost_customer/features/orders/cancel_order.dart';
import 'package:irondost_customer/features/basket/promo_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:irondost_customer/app/provider_retry.dart';

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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
import 'package:irondost_customer/features/home/banners.dart';
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

import '../../test/helpers.dart';

/// Every screen a customer reaches, drawn in light and dark, at normal and at 200% text size.
///
/// At 200% nothing may overflow (Flutter reports an overflow as an error, which fails the test). At normal
/// size every tap target must be big enough and labelled, and all text must contrast with what is behind it.
import 'package:irondost_customer/design/theme.dart';
import 'package:irondost_customer/features/addresses/address_args.dart';
import 'package:irondost_customer/features/addresses/address_form_screen.dart';
import 'package:irondost_customer/features/addresses/map_pin_screen.dart';
import 'package:irondost_customer/features/addresses/place_search_screen.dart';
import 'package:irondost_customer/features/addresses/location_service.dart';
import 'package:irondost_customer/features/auth/otp_screen.dart';
import 'package:irondost_customer/features/auth/login_controller.dart';
import 'package:irondost_customer/features/catalogue/search_screen.dart';
import 'package:irondost_customer/features/checkout/checkout_screen.dart';
import 'package:irondost_customer/features/orders/order_bill_screen.dart';
import 'package:irondost_customer/features/orders/order_confirmed_screen.dart';
import 'package:irondost_customer/features/payment/payment_receipt_screen.dart';
import 'package:irondost_customer/features/payment/payment_screen.dart';
import 'package:irondost_customer/features/payment/payment.dart';
import 'package:irondost_customer/features/payment/payment_repository.dart';
import 'package:irondost_customer/features/payment/razorpay_checkout.dart';
import 'package:irondost_customer/features/push/notification_permission_screen.dart';
import 'package:irondost_customer/features/system/system_screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Outfit', 'Figtree', 'Geist Mono']) {
      final loader = FontLoader(family)
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File('/tmp/irondost-audit-fonts/$family.ttf').readAsBytesSync(),
            ),
          ),
        );
      await loader.load();
    }
    final icon = FontLoader('packages/lucide_icons_flutter/Lucide')
      ..addFont(
        rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
      );
    await icon.load();
    final roboto = FontLoader('Roboto')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('/tmp/irondost-audit-fonts/Roboto.ttf').readAsBytesSync(),
          ),
        ),
      );
    await roboto.load();
    final material = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await material.load();
  });
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
  final startup = startupProvider.overrideWith(
    (ref) async => const Startup(config: config, installedVersion: '2.0.0'),
  );
  final now = DateTime.now();
  final today = DateTime.now()
      .toUtc()
      .add(const Duration(hours: 5, minutes: 30))
      .toIso8601String()
      .substring(0, 10);

  /// Puts [screen] at [path] in a router, with a page behind it to go back to.
  GoRouter at(String path, Widget screen) => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SizedBox()),
      GoRoute(path: path, builder: (_, _) => screen),
    ],
  )..push(path);

  final scenarios = <String, Future<Widget> Function(Brightness b, double scale)>{
    'Home': (b, s) async => auditThemed(
      const HomeScreen(),
      overrides: [
        ...await basketOverrides(
          banners: const [
            BannerDto(
              id: 'campaign',
              imageUrl: 'https://fixtures.example/dasara.png',
              title: 'Dasara: 15% off · Min. order ₹100 · Up to ₹100',
              linkUrl: 'irondost://offers',
              sortOrder: 0,
              isActive: true,
            ),
            BannerDto(
              id: 'campaign-2',
              imageUrl: 'https://fixtures.example/diwali.png',
              title: 'Diwali: 10% off · Min. order ₹100 · Up to ₹100',
              linkUrl: 'irondost://offers',
              sortOrder: 1,
              isActive: true,
            ),
          ],
          promotions: [
            testPromo(
              'WELCOME20',
              '20% off your first order',
              minOrderPaise: 29900,
              maxDiscountPaise: 10000,
              limit: 1,
            ),
          ],
        ),
        addressRepositoryProvider.overrideWithValue(
          FakeAddressRepository([testAddress()]),
        ),
        orderRepositoryProvider.overrideWithValue(
          FakeOrderRepository()
            ..listed.add(
              testOrder(
                status: OrderStatus.processing,
                pieces: 12,
                totalPaise: 18000,
                deliveryDate: '2026-10-06',
              ),
            ),
        ),
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository()..inbox.add(testNotification('n1')),
        ),
        bannerImageProvider.overrideWith(
          (ref, url) => MemoryImage(
            File(
              '../../docs/ui-ux-audit/campaigns/${url.contains('dasara') ? 'dasara' : 'diwali'}-2026.png',
            ).readAsBytesSync(),
          ),
        ),
      ],
      brightness: b,
      textScale: s,
    ),
    'Offline banner': (b, s) async => auditThemed(
      const Scaffold(
        body: Align(alignment: Alignment.bottomCenter, child: OfflineBanner()),
      ),
      overrides: [reachabilityProvider.overrideWith(_Offline.new)],
      brightness: b,
      textScale: s,
    ),
    'Name': (b, s) async => auditThemed(
      const NameScreen(),
      overrides: [sessionProvider.overrideWith(SignedInSession.new)],
      brightness: b,
      textScale: s,
    ),
    'Catalogue': (b, s) async => auditThemed(
      const CatalogueScreen(),
      overrides: await basketOverrides(
        saved: {
          'basket.v1': '{"lines":{"shirt":2,"saree":1},"promoCode":null}',
        },
      ),
      brightness: b,
      textScale: s,
    ),
    'Addresses': (b, s) async => auditRouter(
      at(Routes.addresses, const AddressesScreen()),
      overrides: [
        sessionProvider.overrideWith(SignedInSession.new),
        addressRepositoryProvider.overrideWithValue(
          FakeAddressRepository([
            testAddress(),
            testAddress(id: 'a2', label: 'Work', isPrimary: false),
            testAddress(
              id: 'a3',
              label: 'Parents',
              isPrimary: false,
              serviceable: false,
            ),
          ]),
        ),
      ],
      brightness: b,
      textScale: s,
    ),
    'Welcome': (b, s) async => auditRouter(
      testRouter({
        Routes.welcome: () => const WelcomeScreen(),
      }, initial: Routes.welcome),
      brightness: b,
      textScale: s,
    ),
    'Phone': (b, s) async => auditThemed(
      const PhoneScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(FakeAuth())],
      brightness: b,
      textScale: s,
    ),
    'Basket': (b, s) async => auditThemed(
      const BasketScreen(),
      overrides: await basketOverrides(
        saved: {
          'basket.v1':
              '{"lines":{"shirt":10,"trousers":4,"saree":1},"promoCode":null}',
        },
      ),
      brightness: b,
      textScale: s,
    ),
    'Orders': (b, s) async => auditRouter(
      testRouter({
        Routes.orders: () => const OrdersScreen(),
      }, initial: Routes.orders),
      overrides: [
        orderRepositoryProvider.overrideWithValue(
          FakeOrderRepository()
            ..listed.addAll([
              testOrder(
                id: 'a1',
                number: 'ID001046',
                method: PaymentMethod.online,
                paymentStatus: PaymentStatus.paid,
                paidPaise: 24800,
                pickupDate: today,
              ),
              testOrder(
                id: 'a2',
                number: 'ID001042',
                status: OrderStatus.processing,
                totalPaise: 18000,
                pickedUpAt: DateTime.utc(2026, 10, 1, 12, 10),
                pieces: 12,
              ),
            ]),
        ),
        sessionProvider.overrideWith(SignedInSession.new),
      ],
      brightness: b,
      textScale: s,
    ),
    'Order detail': (b, s) async {
      final order = testOrder(
        id: 'a2',
        number: 'ID001042',
        status: OrderStatus.processing,
        totalPaise: 18000,
        pickedUpAt: DateTime.utc(2026, 10, 1, 12, 10),
        pieces: 12,
      );
      return auditRouter(
        at(
          Routes.order('a2'),
          OrderDetailScreen(orderId: 'a2', initial: order),
        ),
        overrides: [
          orderRepositoryProvider.overrideWithValue(
            FakeOrderRepository()..orders['a2'] = order,
          ),
          ...await basketOverrides(),
        ],
        brightness: b,
        textScale: s,
      );
    },
    'Offers': (b, s) async => auditThemed(
      const OffersScreen(),
      overrides: [
        promotionsProvider.overrideWith(
          (ref) async => [
            testPromo(
              'WELCOME20',
              '20% off your first order',
              minOrderPaise: 29900,
              maxDiscountPaise: 10000,
              limit: 1,
            ),
            testPromo(
              'FRESH15',
              '15% off orders above ₹500',
              value: 15,
              minOrderPaise: 50000,
              maxDiscountPaise: 15000,
              description: 'On any service.',
            ),
            testPromo(
              'FLAT50',
              '₹50 off orders above ₹400',
              type: DiscountType.flat,
              value: 5000,
              minOrderPaise: 40000,
              limit: 2,
            ),
          ],
        ),
      ],
      brightness: b,
      textScale: s,
    ),
    'Offers (empty)': (b, s) async => auditThemed(
      const OffersScreen(),
      overrides: [promotionsProvider.overrideWith((ref) async => [])],
      brightness: b,
      textScale: s,
    ),
    'Offers (offline)': (b, s) async => auditThemed(
      const OffersScreen(),
      overrides: [
        promotionsProvider.overrideWith(
          (ref) async => throw const ApiFailure(ApiFailureKind.offline),
        ),
      ],
      brightness: b,
      textScale: s,
    ),
    'Notifications': (b, s) async => auditRouter(
      testRouter({
        Routes.notifications: () => const NotificationsScreen(),
      }, initial: Routes.notifications),
      overrides: [
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository()
            ..inbox.addAll([
              testNotification(
                'n1',
                title: 'Partner on the way',
                createdAt: now,
              ),
              testNotification(
                'n2',
                type: 'payment_received',
                title: 'Payment received',
                body: '₹248 received for order ID001046.',
                createdAt: now,
                readAt: now,
              ),
              testNotification(
                'n3',
                title: 'We have your clothes',
                createdAt: now.subtract(const Duration(days: 3)),
                readAt: now,
              ),
            ]),
        ),
        sessionProvider.overrideWith(SignedInSession.new),
      ],
      brightness: b,
      textScale: s,
    ),
    'Schedule': (b, s) async => auditThemed(
      const ScheduleScreen(),
      overrides: [
        scheduleRepositoryProvider.overrideWithValue(FakeScheduleRepository()),
        startup,
        ...await basketOverrides(),
      ],
      brightness: b,
      textScale: s,
    ),
    'Account': (b, s) async => auditRouter(
      testRouter({
        Routes.account: () => const AccountScreen(),
      }, initial: Routes.account),
      overrides: [
        sessionProvider.overrideWith(SignedInSession.new),
        addressRepositoryProvider.overrideWithValue(
          FakeAddressRepository([
            testAddress(),
            testAddress(id: 'a2', label: 'Work', isPrimary: false),
          ]),
        ),
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository()..inbox.add(testNotification('n1')),
        ),
        startup,
      ],
      brightness: b,
      textScale: s,
    ),
    'Edit profile': (b, s) async => auditRouter(
      at(Routes.editProfile, const EditProfileScreen()),
      overrides: [sessionProvider.overrideWith(SignedInSession.new)],
      brightness: b,
      textScale: s,
    ),
    'Help': (b, s) async => auditRouter(
      at(Routes.help, const HelpScreen()),
      overrides: [startup],
      brightness: b,
      textScale: s,
    ),
    for (final doc in LegalDoc.values)
      'Legal: ${doc.slug}': (b, s) async => auditRouter(
        at(Routes.legal(doc.slug), LegalScreen(doc: doc)),
        brightness: b,
        textScale: s,
      ),

    'Launch': (b, s) async =>
        auditThemed(const LaunchScreen(), brightness: b, textScale: s),
    'Unavailable': (b, s) async => auditThemed(
      const UnavailableScreen(),
      overrides: [
        startupProvider.overrideWith(
          (ref) async => throw const ApiFailure(ApiFailureKind.offline),
        ),
        sessionProvider.overrideWith(SignedInSession.new),
      ],
      brightness: b,
      textScale: s,
    ),
    'Update': (b, s) async => auditThemed(
      const UpdateScreen(),
      overrides: [startup],
      brightness: b,
      textScale: s,
    ),
    'Paused': (b, s) async => auditThemed(
      const PausedScreen(),
      overrides: [startup, sessionProvider.overrideWith(SignedInSession.new)],
      brightness: b,
      textScale: s,
    ),
    'OTP': (b, s) async => auditThemed(
      const OtpScreen(),
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuth()),
        loginProvider.overrideWith(_AuditLogin.new),
      ],
      brightness: b,
      textScale: s,
    ),
    'Map pin (fallback)': (b, s) async => auditRouter(
      at('/pin', const MapPinScreen(args: PinArgs(onboarding: true))),
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocation()),
        addressRepositoryProvider.overrideWithValue(FakeAddressRepository()),
        sessionProvider.overrideWith(SignedInSession.new),
      ],
      brightness: b,
      textScale: s,
    ),
    'Map outside area': (b, s) async => auditRouter(
      at('/pin', const MapPinScreen(args: PinArgs(onboarding: true))),
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocation()),
        addressRepositoryProvider.overrideWithValue(
          FakeAddressRepository()..areaServiceable = false,
        ),
        sessionProvider.overrideWith(SignedInSession.new),
      ],
      brightness: b,
      textScale: s,
    ),
    'Place search': (b, s) async => auditRouter(
      at('/search', const PlaceSearchScreen()),
      overrides: [locationServiceProvider.overrideWithValue(FakeLocation())],
      brightness: b,
      textScale: s,
    ),
    'Address form': (b, s) async => auditRouter(
      at(
        '/address',
        AddressFormScreen(
          args: FormArgs(draft: AddressDraft.fromAddress(testAddress())),
        ),
      ),
      overrides: [
        addressRepositoryProvider.overrideWithValue(
          FakeAddressRepository([testAddress()]),
        ),
        sessionProvider.overrideWith(SignedInSession.new),
      ],
      brightness: b,
      textScale: s,
    ),
    'Catalogue search': (b, s) async => auditRouter(
      at('/search', const SearchScreen()),
      overrides: await basketOverrides(),
      brightness: b,
      textScale: s,
    ),
    'Basket empty': (b, s) async => auditThemed(
      const BasketScreen(),
      overrides: await basketOverrides(),
      brightness: b,
      textScale: s,
    ),
    'Orders empty': (b, s) async => auditRouter(
      at('/orders', const OrdersScreen()),
      overrides: [
        orderRepositoryProvider.overrideWithValue(FakeOrderRepository()),
        sessionProvider.overrideWith(SignedInSession.new),
      ],
      brightness: b,
      textScale: s,
    ),
    'Checkout': (b, s) async => auditRouter(
      at('/checkout', const CheckoutScreen()),
      overrides: [
        ...await basketOverrides(
          saved: {
            'basket.v1': '{"lines":{"shirt":10,"trousers":4,"saree":1},"promoCode":null}',
          },
        ),
        scheduleRepositoryProvider.overrideWithValue(FakeScheduleRepository()),
        orderRepositoryProvider.overrideWithValue(FakeOrderRepository()),
        addressRepositoryProvider.overrideWithValue(
          FakeAddressRepository([testAddress()]),
        ),
      ],
      brightness: b,
      textScale: s,
    ),
    'Confirmed': (b, s) async => auditRouter(
      at(
        '/confirmed',
        OrderConfirmedScreen(orderId: 'o-1', initial: testOrder()),
      ),
      overrides: [
        ...await basketOverrides(),
        orderRepositoryProvider.overrideWithValue(FakeOrderRepository()),
      ],
      brightness: b,
      textScale: s,
    ),
    'Order bill': (b, s) async => auditRouter(
      at('/bill', OrderBillScreen(orderId: 'o-1', initial: testOrder())),
      overrides: [
        orderRepositoryProvider.overrideWithValue(FakeOrderRepository()),
      ],
      brightness: b,
      textScale: s,
    ),
    'Payment receipt': (b, s) async => auditRouter(
      at(
        '/paid',
        PaymentReceiptScreen(
          orderId: 'o-1',
          initial: testOrder(
            method: PaymentMethod.online,
            paymentStatus: PaymentStatus.paid,
            paidPaise: 24800,
          ),
        ),
      ),
      overrides: [
        orderRepositoryProvider.overrideWithValue(
          FakeOrderRepository()
            ..orders['o-1'] = testOrder(
              method: PaymentMethod.online,
              paymentStatus: PaymentStatus.paid,
              paidPaise: 24800,
            ),
        ),
      ],
      brightness: b,
      textScale: s,
    ),
    'Payment failed': (b, s) async {
      final orders = FakeOrderRepository()
        ..orders['o-1'] = testOrder(method: PaymentMethod.online);
      return auditRouter(
        at(
          '/pay',
          PaymentScreen(orderId: 'o-1', initial: orders.orders['o-1']),
        ),
        overrides: [
          orderRepositoryProvider.overrideWithValue(orders),
          paymentRepositoryProvider.overrideWithValue(
            FakePaymentRepository(orders),
          ),
          razorpayCheckoutProvider.overrideWithValue(
            FakeRazorpayCheckout([
              const CheckoutFailed(code: 100, message: 'declined'),
            ]),
          ),
          paymentPollingProvider.overrideWithValue(instantPolling),
        ],
        brightness: b,
        textScale: s,
      );
    },
    'Notification permission': (b, s) async => auditRouter(
      at('/permission', const NotificationPermissionScreen()),
      overrides: await basketOverrides(),
      brightness: b,
      textScale: s,
    ),
  };

  // Supplemental lifecycle states are kept separate from the original 47-view comparison.
  if (const bool.fromEnvironment('AUDIT_EXTRA_STATES')) {
    scenarios.clear();
    for (final search in [false, true]) {
      for (final state in ['Loading', 'Offline', 'Empty']) {
        scenarios['${search ? 'Search' : 'Catalogue'} $state'] = (b, s) async =>
            auditRouter(
              at(
                search ? '/search' : '/book',
                search ? const SearchScreen() : const CatalogueScreen(),
              ),
              overrides: await basketOverrides(
                load: state == 'Loading'
                    ? () => Completer<List<CatalogCategoryDto>>().future
                    : state == 'Offline'
                    ? () async => throw const ApiFailure(ApiFailureKind.offline)
                    : () async => [],
              ),
              brightness: b,
              textScale: s,
            );
      }
    }
    for (final state in ['Loading', 'Offline', 'Empty']) {
      scenarios['Notifications $state'] = (b, s) async => auditRouter(
        at('/notifications', const NotificationsScreen()),
        overrides: [
          sessionProvider.overrideWith(SignedInSession.new),
          notificationRepositoryProvider.overrideWithValue(
            state == 'Loading'
                ? _PendingNotifications()
                : (FakeNotificationRepository()
                    ..listFailure = state == 'Offline'
                        ? const ApiFailure(ApiFailureKind.offline)
                        : null),
          ),
        ],
        brightness: b,
        textScale: s,
      );
    }
    for (final state in ['Loading', 'Offline']) {
      scenarios['Orders $state'] = (b, s) async => auditRouter(
        at('/orders', const OrdersScreen()),
        overrides: [
          sessionProvider.overrideWith(SignedInSession.new),
          orderRepositoryProvider.overrideWithValue(
            state == 'Loading'
                ? _PendingOrders()
                : (FakeOrderRepository()
                    ..listFailure = const ApiFailure(ApiFailureKind.offline)),
          ),
        ],
        brightness: b,
        textScale: s,
      );
    }
    scenarios['Offers Loading'] = (b, s) async => auditRouter(
      at('/offers', const OffersScreen()),
      overrides: [
        promotionsProvider.overrideWith(
          (ref) => Completer<List<PromotionDto>>().future,
        ),
      ],
      brightness: b,
      textScale: s,
    );
  }
  if (const bool.fromEnvironment('AUDIT_KEYBOARD')) {
    const forms = {
      'Name',
      'Phone',
      'OTP',
      'Edit profile',
      'Address form',
      'Catalogue search',
      'Place search',
    };
    scenarios.removeWhere((name, _) => !forms.contains(name));
  }

  if (const bool.fromEnvironment('AUDIT_STRESS')) {
    for (final entry in scenarios.entries) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'stress ${entry.key} ${brightness.name} ${const int.fromEnvironment('AUDIT_WIDTH', defaultValue: 320)}dp 200%',
          (tester) async {
            const width = int.fromEnvironment('AUDIT_WIDTH', defaultValue: 320);
            tester.view
              ..physicalSize = const Size(width * 2.0, 740 * 2)
              ..devicePixelRatio = 2;
            addTearDown(tester.view.reset);
            if (const bool.fromEnvironment('AUDIT_KEYBOARD')) {
              tester.view.viewInsets = const FakeViewPadding(bottom: 600);
            }
            final errors = <String>[];
            final original = FlutterError.onError;
            FlutterError.onError = (details) => errors.add(details.toString());
            try {
              await tester.pumpWidget(await entry.value(brightness, 2));
              await tester.pump(
                quoteDebounce + const Duration(milliseconds: 10),
              );
              await tester.pump(const Duration(milliseconds: 500));
              await tester.pump(const Duration(milliseconds: 500));
              await tester.pumpWidget(const SizedBox());
              await tester.pump();
            } finally {
              FlutterError.onError = original;
            }
            expect(errors, isEmpty);
          },
        );
      }
    }
    return;
  }
  for (final entry in scenarios.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('capture ${entry.key} ${brightness.name}', (tester) async {
        tester.view
          ..physicalSize = const Size(
            int.fromEnvironment('AUDIT_WIDTH', defaultValue: 390) * 2.0,
            844 * 2,
          )
          ..devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        if (const bool.fromEnvironment('AUDIT_KEYBOARD')) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 600);
        }
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: await entry.value(
              brightness,
              double.parse(
                const String.fromEnvironment('AUDIT_SCALE', defaultValue: '1'),
              ),
            ),
          ),
        );
        await tester.pump(quoteDebounce + const Duration(milliseconds: 10));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final img = await boundary.toImage(pixelRatio: 2);
          return (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer
              .asUint8List();
        });
        final slug = entry.key
            .toLowerCase()
            .replaceAll(RegExp('[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'-$'), '');
        await tester.runAsync(() async {
          await File(
            '${const String.fromEnvironment('AUDIT_CAPTURE_DIR', defaultValue: '../../docs/ui-ux-audit/screens')}/$slug-${brightness.name}.png',
          ).writeAsBytes(bytes!);
        });
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
    }
  }

  if (const bool.fromEnvironment('AUDIT_EXTRA_STATES') ||
      const bool.fromEnvironment('AUDIT_KEYBOARD')) {
    return;
  }

  for (final brightness in Brightness.values) {
    for (final name in [
      'Address picker',
      'Promo sheet',
      'Delivery sheet',
      'Pay due sheet',
      'Cancel sheet',
      'Log out sheet',
      'Delete account sheet',
      'Delete blocked sheet',
    ]) {
      testWidgets('capture $name ${brightness.name}', (tester) async {
        tester.view
          ..physicalSize = const Size(
            int.fromEnvironment('AUDIT_WIDTH', defaultValue: 390) * 2.0,
            844 * 2,
          )
          ..devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        if (const bool.fromEnvironment('AUDIT_KEYBOARD')) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 600);
        }
        final key = GlobalKey();
        final order = testOrder();
        final accounts = FakeAccountRepository()
          ..failure = const ApiFailure(
            ApiFailureKind.rejected,
            statusCode: 409,
            code: 'ACTIVE_ORDERS',
            details: {'activeOrders': 2},
          );
        final nav = GoRouter(
          initialLocation: '/audit',
          routes: [
            GoRoute(
              path: '/audit',
              builder: (context, state) => Consumer(
                builder: (context, ref, _) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () {
                        switch (name) {
                          case 'Address picker':
                            showAddressPicker(context);
                            break;
                          case 'Promo sheet':
                            showPromoSheet(context);
                            break;
                          case 'Delivery sheet':
                            showDeliverySheet(context);
                            break;
                          case 'Pay due sheet':
                            showPayDueSheet(context, order);
                            break;
                          case 'Cancel sheet':
                            showCancelSheet(context, order);
                            break;
                          default:
                            context.push('/account');
                        }
                      },
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            ),
            GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
          ],
        );
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: auditRouter(
              nav,
              brightness: brightness,
              overrides: [
                ...await basketOverrides(
                  saved: {
                    'basket.v1':
                        '{"lines":{"shirt":10,"saree":1},"promoCode":null}',
                  },
                  promotions: [
                    testPromo('WELCOME20', '20% off your first order'),
                  ],
                ),
                addressRepositoryProvider.overrideWithValue(
                  FakeAddressRepository([
                    testAddress(),
                    testAddress(id: 'a2', label: 'Work', isPrimary: false),
                  ]),
                ),
                scheduleRepositoryProvider.overrideWithValue(
                  FakeScheduleRepository(),
                ),
                orderRepositoryProvider.overrideWithValue(
                  FakeOrderRepository(),
                ),
                accountRepositoryProvider.overrideWithValue(accounts),
                notificationRepositoryProvider.overrideWithValue(
                  FakeNotificationRepository(),
                ),
                startup,
              ],
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        final container = ProviderScope.containerOf(
          tester.element(find.byType(Scaffold).first),
        );
        await tester.runAsync(() => container.read(sessionProvider.future));
        if (name == 'Delivery sheet') {
          container
              .read(scheduleChoiceProvider.notifier)
              .pickPickup(testSlot(testToday, TimeSlot.evening));
        }
        await tester.tap(find.text('Open'));
        await tester.pump(const Duration(milliseconds: 500));
        if (name.contains('account') ||
            name.contains('blocked') ||
            name == 'Log out sheet') {
          final row = name == 'Log out sheet' ? 'Log out' : 'Delete account';
          await tester.scrollUntilVisible(
            find.text(row),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(find.text(row));
          await tester.tap(find.text(row));
          await tester.pump(const Duration(milliseconds: 500));
          if (name == 'Delete blocked sheet') {
            final button = find.widgetWithText(FilledButton, 'Delete account');
            await tester.ensureVisible(button);
            await tester.pump(const Duration(milliseconds: 200));
            await tester.tap(button);
            await tester.pump(const Duration(milliseconds: 500));
            expect(find.text('Finish your orders first'), findsOneWidget);
          }
        }
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 80));
        });
        await tester.pump(const Duration(milliseconds: 500));
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final img = await boundary.toImage(pixelRatio: 2);
          return (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer
              .asUint8List();
        });
        final slug = name.toLowerCase().replaceAll(' ', '-');
        await tester.runAsync(() async {
          await File(
            '${const String.fromEnvironment('AUDIT_CAPTURE_DIR', defaultValue: '../../docs/ui-ux-audit/screens')}/$slug-${brightness.name}.png',
          ).writeAsBytes(bytes!);
        });
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
    }
  }
}

class _Offline extends Reachability {
  @override
  bool build() => false;
}

class _AuditLogin extends LoginController {
  @override
  LoginState build() => const LoginState(
    phone: '9876543210',
    challenge: PhoneChallenge(phone: '9876543210', verificationId: 'audit'),
  );
}

Widget auditThemed(
  Widget child, {
  List<Override> overrides = const [],
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) => ProviderScope(
  retry: noAutomaticRetry,
  overrides: overrides,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildTheme(
      brightness,
      font: (family, style) =>
          style.copyWith(fontFamily: family, fontFamilyFallback: ['Roboto']),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: child,
  ),
);
Widget auditRouter(
  GoRouter router, {
  List<Override> overrides = const [],
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) => ProviderScope(
  retry: noAutomaticRetry,
  overrides: overrides,
  child: MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: buildTheme(
      brightness,
      font: (family, style) =>
          style.copyWith(fontFamily: family, fontFamilyFallback: ['Roboto']),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    routerConfig: router,
  ),
);

class _PendingNotifications extends FakeNotificationRepository {
  @override
  Future<NotificationPageDto> list({int page = 1, int pageSize = 20}) =>
      Completer<NotificationPageDto>().future;
}

class _PendingOrders extends FakeOrderRepository {
  @override
  Future<OrderPageDto> list(Scope scope, {int page = 1, int pageSize = 20}) =>
      Completer<OrderPageDto>().future;
}
