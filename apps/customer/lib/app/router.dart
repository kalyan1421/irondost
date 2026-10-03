import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../features/account/account_screen.dart';
import '../features/addresses/address_args.dart';
import '../features/addresses/address_form_screen.dart';
import '../features/addresses/addresses_controller.dart';
import '../features/addresses/addresses_screen.dart';
import '../features/addresses/map_pin_screen.dart';
import '../features/addresses/place_search_screen.dart';
import '../features/auth/name_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/phone_screen.dart';
import '../features/auth/session.dart';
import '../features/auth/welcome_screen.dart';
import '../features/basket/basket_screen.dart';
import '../features/catalogue/catalogue_screen.dart';
import '../features/catalogue/search_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/orders/order_confirmed_screen.dart';
import '../features/payment/payment_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../features/home/home_screen.dart';
import '../features/offers/offers_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/startup/startup.dart';
import '../features/system/system_screens.dart';
import 'redirect.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-runs the redirect whenever startup or session state changes.
  final refresh = ValueNotifier(0);
  ref
    ..listen(startupProvider, (_, _) => refresh.value++)
    ..listen(sessionProvider, (_, _) => refresh.value++)
    ..listen(addressesProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.launch,
    refreshListenable: refresh,
    redirect: (context, state) => redirectFor(
      startup: ref.read(startupProvider),
      session: ref.read(sessionProvider),
      addresses: ref.read(addressesProvider),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: Routes.launch, builder: (_, _) => const LaunchScreen()),
      GoRoute(path: Routes.unavailable, builder: (_, _) => const UnavailableScreen()),
      GoRoute(path: Routes.update, builder: (_, _) => const UpdateScreen()),
      GoRoute(path: Routes.paused, builder: (_, _) => const PausedScreen()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const PhoneScreen(),
        routes: [GoRoute(path: 'code', builder: (_, _) => const OtpScreen())],
      ),
      GoRoute(path: Routes.setupName, builder: (_, _) => const NameScreen()),
      GoRoute(
        path: Routes.setupPin,
        builder: (_, state) => MapPinScreen(args: (state.extra as PinArgs?) ?? const PinArgs(onboarding: true)),
      ),
      GoRoute(path: Routes.setupDetails, builder: (_, state) => AddressFormScreen(args: state.extra! as FormArgs)),
      GoRoute(path: Routes.addressSearch, builder: (_, _) => const PlaceSearchScreen()),
      GoRoute(path: Routes.addressPin, builder: (_, state) => MapPinScreen(args: (state.extra as PinArgs?) ?? const PinArgs())),
      GoRoute(path: Routes.addressDetails, builder: (_, state) => AddressFormScreen(args: state.extra! as FormArgs)),
      GoRoute(
        path: Routes.book,
        builder: (_, state) => CatalogueScreen(service: state.uri.queryParameters['service']),
        routes: [GoRoute(path: 'search', builder: (_, _) => const SearchScreen())],
      ),
      GoRoute(
        path: Routes.basket,
        builder: (_, _) => const BasketScreen(),
        routes: [
          GoRoute(
            path: 'schedule',
            builder: (_, _) => const ScheduleScreen(),
            routes: [GoRoute(path: 'checkout', builder: (_, _) => const CheckoutScreen())],
          ),
        ],
      ),
      GoRoute(
        path: Routes.orderConfirmed,
        builder: (_, state) => OrderConfirmedScreen(orderId: state.pathParameters['id']!, initial: state.extra as OrderDto?),
      ),
      GoRoute(
        path: Routes.orderPay,
        builder: (_, state) => PaymentScreen(orderId: state.pathParameters['id']!, initial: state.extra as OrderDto?),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.orders, builder: (_, _) => const OrdersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.offers, builder: (_, _) => const OffersScreen())]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.account,
                builder: (_, _) => const AccountScreen(),
                routes: [GoRoute(path: 'addresses', builder: (_, _) => const AddressesScreen())],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
