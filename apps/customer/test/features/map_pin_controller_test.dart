import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondost_customer/features/addresses/address_repository.dart';
import 'package:irondost_customer/features/addresses/location_service.dart';
import 'package:irondost_customer/features/addresses/map_pin_controller.dart';
import 'package:irondost_customer/features/addresses/place.dart';

import '../helpers.dart';

void main() {
  late FakeLocation location;
  late FakeAddressRepository addresses;
  late ProviderContainer container;

  setUp(() {
    location = FakeLocation();
    addresses = FakeAddressRepository();
    container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(location),
        addressRepositoryProvider.overrideWithValue(addresses),
      ],
    );
    addTearDown(container.dispose);
    // autoDispose: keep it alive for the test.
    container.listen(mapPinProvider, (_, _) {});
  });

  MapPinController pin() => container.read(mapPinProvider.notifier);
  MapPinState state() => container.read(mapPinProvider);

  test('uses the phone location and checks the service area', () async {
    final place = await pin().useCurrentLocation();
    expect(place?.street, 'Road No. 12');
    expect(state().place?.title, 'Road No. 12, Banjara Hills');
    expect(state().access, LocationAccess.granted);
    expect(state().outsideArea, isFalse);
    expect(state().resolving, isFalse);
    expect(addresses.checked.single.pincode, '500034');
  });

  test('flags a place outside the service area', () async {
    addresses.areaServiceable = false;
    await pin().useCurrentLocation();
    expect(state().outsideArea, isTrue);
    expect(state().area?.reason?.name, 'outsideRadius');
  });

  test('lets the customer save when the area check cannot run', () async {
    addresses.areaFails = true;
    await pin().useCurrentLocation();
    expect(state().place, isNotNull);
    expect(state().areaCheckFailed, isTrue);
    expect(state().outsideArea, isFalse, reason: 'the API checks again when booking');
  });

  test('explains denied, blocked and switched-off location', () async {
    for (final access in [LocationAccess.denied, LocationAccess.deniedForever, LocationAccess.serviceOff]) {
      location.access = access;
      expect(await pin().useCurrentLocation(), isNull);
      expect(state().access, access);
      expect(state().locationBlocked, isTrue);
      expect(state().locating, isFalse);
      expect(state().place, isNull);
    }
  });

  test('a location fix that times out is not "blocked"', () async {
    location.here = null;
    expect(await pin().useCurrentLocation(), isNull);
    expect(state().locationBlocked, isFalse);
  });

  test('describes the spot when the map stops moving', () async {
    await pin().pinMoved(17.5, 78.5);
    expect(location.reversed.single, (17.5, 78.5));
    expect(state().place?.latitude, 17.5);
  });

  test('ignores an older lookup that finishes after a newer one', () async {
    final slow = Completer<Place?>();
    location.holdReverse = slow;
    final first = pin().pinMoved(17.1, 78.1); // waits on [slow]
    location.holdReverse = null;
    await pin().pinMoved(17.2, 78.2);
    slow.complete(const Place(latitude: 17.1, longitude: 78.1, street: 'Old'));
    await first;
    expect(state().place?.latitude, 17.2);
  });

  test('starts on an existing address when editing', () async {
    await pin().start(const Place(latitude: 17.4, longitude: 78.4, street: 'Road No. 36', city: 'Hyderabad', state: 'Telangana', pincode: '500033'));
    expect(state().place?.street, 'Road No. 36');
    expect(addresses.checked, hasLength(1));
  });
}
