import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

import 'place.dart';

enum LocationAccess {
  unknown,
  granted,

  /// The customer said no this time; we can ask again.
  denied,

  /// Blocked in system settings; only Settings can change it.
  deniedForever,

  /// Location services are switched off on the phone.
  serviceOff,
}

/// Device location and address lookup. Uses the phone's own geocoder, so no map key is needed.
abstract class LocationService {
  /// Checks (and, the first time, asks for) permission to use the phone's location.
  Future<LocationAccess> requestAccess();

  /// The customer's current position as a place, or null when it can't be found in time.
  Future<Place?> currentPlace();

  /// The address at a map position.
  Future<Place?> reverse(double latitude, double longitude);

  /// Addresses matching what the customer typed, best first.
  Future<List<Place>> search(String query);

  Future<void> openSettings(LocationAccess access);
}

final locationServiceProvider = Provider<LocationService>((_) => DeviceLocationService());

class DeviceLocationService implements LocationService {
  final _geocoding = geo.Geocoding();

  @override
  Future<LocationAccess> requestAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    return switch (permission) {
      LocationPermission.whileInUse || LocationPermission.always => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.deniedForever,
      _ => LocationAccess.denied,
    };
  }

  @override
  Future<Place?> currentPlace() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)),
      );
      return await reverse(position.latitude, position.longitude);
    } on TimeoutException {
      return null;
    } on LocationServiceDisabledException {
      return null;
    }
  }

  @override
  Future<Place?> reverse(double latitude, double longitude) async {
    try {
      final marks = await _geocoding.placemarkFromCoordinates(latitude, longitude);
      if (marks.isEmpty) return Place(latitude: latitude, longitude: longitude);
      return Place.fromPlacemark(marks.first, latitude: latitude, longitude: longitude);
    } on Exception {
      // No network or the geocoder is throttling: the pin is still valid, the form asks for the rest.
      return Place(latitude: latitude, longitude: longitude);
    }
  }

  @override
  Future<List<Place>> search(String query) async {
    final text = query.trim();
    if (text.length < 3) return const [];
    try {
      final locations = await _geocoding.locationFromAddress(text.toLowerCase().contains('india') ? text : '$text, India');
      final places = await Future.wait([for (final l in locations.take(5)) reverse(l.latitude, l.longitude)]);
      return places.whereType<Place>().toList();
    } on Exception {
      // The phone's geocoder reports "nothing found" as an error; treat any lookup failure as no matches.
      return const [];
    }
  }

  @override
  Future<void> openSettings(LocationAccess access) async {
    if (access == LocationAccess.serviceOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
