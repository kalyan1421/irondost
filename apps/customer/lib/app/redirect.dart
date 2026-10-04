import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/export.dart';
import '../features/auth/session.dart';
import '../features/startup/startup.dart';
import 'routes.dart';

/// Where the app should be, given startup and session state. Pure, so it is unit-tested.
///
/// Order: API reachable → build still supported → signed in → profile complete → has an address → tabs.
///
/// [addresses] is only consulted once the customer is signed in with a complete profile.
String? redirectFor({
  required AsyncValue<Startup> startup,
  required AsyncValue<Session> session,
  required AsyncValue<List<AddressDto>> addresses,
  required String location,
}) {
  // Policies remain readable before sign-in, including during an API outage.
  if (Routes.publicLegalRoutes.contains(location)) return null;

  String? to(String target) => location == target ? null : target;

  // While a retry runs from the error screen, stay there (its button shows the spinner).
  if (location == Routes.unavailable &&
      (startup.isLoading || session.isLoading) &&
      (startup.hasError || session.hasError)) {
    return null;
  }
  if (startup.hasError && !startup.isLoading) return to(Routes.unavailable);
  final config = startup.value;
  if (config == null) return to(Routes.launch);
  if (config.updateRequired) return to(Routes.update);

  if (session.hasError && !session.isLoading) return to(Routes.unavailable);
  final s = session.value;
  if (s == null || (session.isLoading && s is! SignedOut)) {
    // Keep the code screen up while the session starts after a correct code.
    return location == Routes.loginCode ? null : to(Routes.launch);
  }

  return switch (s) {
    SignedOut() || WrongApp() =>
      Routes.signedOutRoutes.contains(location) ? null : Routes.welcome,
    AccountPaused() => to(Routes.paused),
    SignedIn(:final profile) when !profile.isComplete => to(Routes.setupName),
    SignedIn() => _signedIn(addresses, location),
  };
}

String? _signedIn(AsyncValue<List<AddressDto>> addresses, String location) {
  if (addresses.hasError && !addresses.isLoading) {
    return location == Routes.unavailable ? null : Routes.unavailable;
  }
  // Right after sign-in the list is still the empty one from when nobody was signed in, while the real one loads.
  // Treat that as not loaded yet: otherwise a returning customer is sent to address setup (and asked for location) first.
  final list = addresses.isLoading && (addresses.value?.isEmpty ?? true)
      ? null
      : addresses.value;
  if (list == null) return location == Routes.launch ? null : Routes.launch;
  // Everyone needs a pickup address before the tabs; saving one ends setup by itself.
  if (list.isEmpty) {
    return Routes.setupRoutes.contains(location) ? null : Routes.setupPin;
  }
  final leaving =
      Routes.signedOutRoutes.contains(location) ||
      Routes.gateRoutes.contains(location) ||
      location == Routes.setupPin ||
      location == Routes.setupDetails;
  return leaving ? Routes.home : null;
}
