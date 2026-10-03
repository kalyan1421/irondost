import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/app/redirect.dart';
import 'package:irondost_customer/app/routes.dart';
import 'package:irondost_customer/data/api_client.dart';
import 'package:irondost_customer/features/auth/session.dart';
import 'package:irondost_customer/features/startup/startup.dart';

void main() {
  const config = PublicConfigDto(
    appName: 'IronDost',
    supportPhone: '+919063290012',
    supportEmail: null,
    minOrderPaise: 0,
    deliveryFeePaise: 0,
    freeDeliveryAbovePaise: null,
    minTurnaroundHours: 20,
    maxAdvanceDays: 30,
    slots: [],
  );
  AppVersionDto version(String min, String latest) => AppVersionDto(
        app: ClientApp.customer,
        platform: DevicePlatform.android,
        minVersion: min,
        latestVersion: latest,
        storeUrl: null,
        message: null,
      );
  const ok = AsyncData(Startup(config: config, installedVersion: '2.0.0'));
  const complete = Profile(id: 'u1', phone: '+919876543210', name: 'Priya Sharma', isComplete: true);
  const incomplete = Profile(id: 'u1', phone: '+919876543210', isComplete: false);

  const home = AddressDto(
    id: 'a1',
    label: 'Home',
    houseNo: '302',
    building: 'Sai Residency',
    street: 'Road No. 12',
    area: 'Banjara Hills',
    landmark: null,
    city: 'Hyderabad',
    state: 'Telangana',
    pincode: '500034',
    latitude: 17.4126,
    longitude: 78.4482,
    isPrimary: true,
    formatted: '302, Sai Residency, Road No. 12, Banjara Hills, Hyderabad 500034',
    serviceable: true,
    notServiceableReason: null,
  );
  const withAddress = AsyncData<List<AddressDto>>([home]);

  String? go(
    String location, {
    AsyncValue<Startup> startup = ok,
    required AsyncValue<Session> session,
    AsyncValue<List<AddressDto>> addresses = withAddress,
  }) =>
      redirectFor(startup: startup, session: session, addresses: addresses, location: location);

  test('shows the launch screen until startup and session are known', () {
    expect(go(Routes.home, startup: const AsyncLoading(), session: const AsyncLoading()), Routes.launch);
    expect(go(Routes.home, session: const AsyncLoading()), Routes.launch);
    expect(go(Routes.launch, session: const AsyncLoading()), isNull);
  });

  test('sends offline and server failures to the unavailable screen', () {
    expect(
      go(Routes.home, startup: const AsyncError(ApiFailure(ApiFailureKind.offline), StackTrace.empty), session: const AsyncLoading()),
      Routes.unavailable,
    );
    expect(go(Routes.home, session: const AsyncError(ApiFailure(ApiFailureKind.server), StackTrace.empty)), Routes.unavailable);
  });

  test('blocks builds below the minimum version', () {
    final old = AsyncData(Startup(config: config, installedVersion: '2.0.0', version: version('2.1.0', '2.1.0')));
    expect(go(Routes.home, startup: old, session: const AsyncData(SignedIn(complete))), Routes.update);
    final newer = AsyncData(Startup(config: config, installedVersion: '2.0.0', version: version('1.9.0', '2.1.0')));
    expect(newer.value.updateAvailable, isTrue);
    expect(go(Routes.home, startup: newer, session: const AsyncData(SignedIn(complete))), isNull);
  });

  test('keeps signed-out customers on the sign-in screens', () {
    expect(go(Routes.home, session: const AsyncData(SignedOut())), Routes.welcome);
    expect(go(Routes.login, session: const AsyncData(SignedOut())), isNull);
    expect(go(Routes.loginCode, session: const AsyncData(SignedOut())), isNull);
  });

  test('stays on the code screen while the session starts', () {
    expect(go(Routes.loginCode, session: const AsyncLoading()), isNull);
  });

  test('asks for a name before the tabs', () {
    expect(go(Routes.home, session: const AsyncData(SignedIn(incomplete))), Routes.setupName);
    expect(go(Routes.loginCode, session: const AsyncData(SignedIn(complete))), Routes.home);
    expect(go(Routes.orders, session: const AsyncData(SignedIn(complete))), isNull);
  });

  test('sends customers without an address to setup, and lets them in once they save one', () {
    const none = AsyncData<List<AddressDto>>([]);
    const signedIn = AsyncData<Session>(SignedIn(complete));
    expect(go(Routes.home, session: signedIn, addresses: none), Routes.setupPin);
    expect(go(Routes.setupPin, session: signedIn, addresses: none), isNull);
    expect(go(Routes.setupDetails, session: signedIn, addresses: none), isNull);
    expect(go(Routes.addressSearch, session: signedIn, addresses: none), isNull);
    // Saved: setup ends by itself.
    expect(go(Routes.setupDetails, session: signedIn), Routes.home);
    expect(go(Routes.setupPin, session: signedIn), Routes.home);
    // Adding another address later is not setup.
    expect(go(Routes.addressPin, session: signedIn), isNull);
    expect(go(Routes.addresses, session: signedIn), isNull);
  });

  test('waits for addresses before showing the tabs, and reports a failure', () {
    const signedIn = AsyncData<Session>(SignedIn(complete));
    expect(go(Routes.home, session: signedIn, addresses: const AsyncLoading()), Routes.launch);
    expect(go(Routes.home, session: signedIn, addresses: const AsyncError(ApiFailure(ApiFailureKind.offline), StackTrace.empty)), Routes.unavailable);
  });

  test('shows the paused screen for disabled accounts', () {
    expect(go(Routes.home, session: const AsyncData(AccountPaused())), Routes.paused);
  });
}
