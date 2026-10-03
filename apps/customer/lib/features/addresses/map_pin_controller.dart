import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';
import 'address_repository.dart';
import 'location_service.dart';
import 'place.dart';

const _keep = Object();

class MapPinState {
  const MapPinState({
    this.place,
    this.resolving = false,
    this.area,
    this.areaCheckFailed = false,
    this.access = LocationAccess.unknown,
    this.locating = false,
  });

  /// The address under the pin.
  final Place? place;

  /// Looking up the address or checking the service area.
  final bool resolving;

  /// IronDost's answer for [place]; null until checked.
  final ServiceAreaCheckDto? area;

  /// The check couldn't run (offline). Saving is still allowed; the API checks again when booking.
  final bool areaCheckFailed;
  final LocationAccess access;
  final bool locating;

  bool get outsideArea => area != null && !area!.serviceable;
  bool get locationBlocked => access == LocationAccess.denied || access == LocationAccess.deniedForever || access == LocationAccess.serviceOff;

  MapPinState copyWith({
    Object? place = _keep,
    bool? resolving,
    Object? area = _keep,
    bool? areaCheckFailed,
    LocationAccess? access,
    bool? locating,
  }) =>
      MapPinState(
        place: identical(place, _keep) ? this.place : place as Place?,
        resolving: resolving ?? this.resolving,
        area: identical(area, _keep) ? this.area : area as ServiceAreaCheckDto?,
        areaCheckFailed: areaCheckFailed ?? this.areaCheckFailed,
        access: access ?? this.access,
        locating: locating ?? this.locating,
      );
}

final mapPinProvider = NotifierProvider.autoDispose<MapPinController, MapPinState>(MapPinController.new);

/// Which place the pin is on, whether IronDost serves it, and whether the phone's location is usable.
class MapPinController extends Notifier<MapPinState> {
  int _request = 0;

  @override
  MapPinState build() => const MapPinState();

  LocationService get _location => ref.read(locationServiceProvider);
  AddressRepository get _addresses => ref.read(addressRepositoryProvider);

  /// Starts on [place] (editing an address); otherwise nothing is chosen until the customer
  /// searches, moves the map or uses their location.
  Future<void> start(Place? place) async {
    if (place != null) await choose(place);
  }

  /// Asks for permission if needed, then moves to where the customer is. Returns that place.
  Future<Place?> useCurrentLocation() async {
    state = state.copyWith(locating: true);
    final access = await _location.requestAccess();
    // The customer may have left the screen while the permission prompt or GPS fix was pending.
    if (!ref.mounted) return null;
    if (access != LocationAccess.granted) {
      state = state.copyWith(access: access, locating: false);
      return null;
    }
    final place = await _location.currentPlace();
    if (!ref.mounted) return null;
    state = state.copyWith(access: place == null ? LocationAccess.unknown : LocationAccess.granted, locating: false);
    if (place != null) await choose(place);
    return place;
  }

  /// The map stopped moving: describe the spot under the pin.
  Future<void> pinMoved(double latitude, double longitude) async {
    final request = ++_request;
    state = state.copyWith(resolving: true);
    final place = await _location.reverse(latitude, longitude);
    if (!ref.mounted || request != _request || place == null) return;
    await _resolved(place, request);
  }

  /// A search result, a saved address, or the customer's location.
  Future<void> choose(Place place) async {
    final request = ++_request;
    state = state.copyWith(place: place, resolving: true, area: null, areaCheckFailed: false);
    await _resolved(place, request);
  }

  Future<void> _resolved(Place place, int request) async {
    state = state.copyWith(place: place, resolving: true, area: null, areaCheckFailed: false);
    ServiceAreaCheckDto? area;
    var failed = false;
    try {
      area = await _addresses.checkArea(place);
    } catch (_) {
      failed = true;
    }
    if (!ref.mounted || request != _request) return;
    state = state.copyWith(place: place, resolving: false, area: area, areaCheckFailed: failed);
  }
}
