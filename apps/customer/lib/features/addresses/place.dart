import 'package:geocoding/geocoding.dart' as geo;

/// A place on the map, as far as the device's geocoder could describe it.
/// Fields the geocoder couldn't fill are null; the address form asks for what's missing.
class Place {
  const Place({required this.latitude, required this.longitude, this.street, this.area, this.city, this.state, this.pincode});

  final double latitude;
  final double longitude;
  final String? street;

  /// Neighbourhood, e.g. Banjara Hills.
  final String? area;
  final String? city;
  final String? state;
  final String? pincode;

  static final _pincode = RegExp(r'^[1-9]\d{5}$');

  factory Place.fromPlacemark(geo.Placemark p, {required double latitude, required double longitude}) {
    String? clean(String? s) {
      final t = s?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    final postal = clean(p.postalCode)?.replaceAll(RegExp(r'\s'), '');
    // iOS often names a spot after its neighbourhood: don't show or save it twice.
    final street = clean(p.thoroughfare) ?? clean(p.street) ?? clean(p.name);
    final subLocality = clean(p.subLocality);
    return Place(
      latitude: latitude,
      longitude: longitude,
      street: street,
      area: subLocality == street ? null : subLocality,
      city: clean(p.locality) ?? clean(p.subAdministrativeArea),
      state: clean(p.administrativeArea),
      pincode: postal != null && _pincode.hasMatch(postal) ? postal : null,
    );
  }

  /// "Road No. 12, Banjara Hills": the first line of the confirm sheet.
  String get title {
    final parts = <String>[
      ?street,
      if (area != null && area != street) area!,
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    return city ?? 'Selected location';
  }

  /// "Hyderabad, Telangana 500034": the second line.
  String get subtitle {
    final region = [?city, ?state].join(', ');
    return [region, ?pincode].where((s) => s.isNotEmpty).join(' ');
  }

  /// What the API needs to save an address (street, city, state and a 6-digit PIN code).
  bool get isComplete => street != null && city != null && state != null && pincode != null;

  Place copyWith({String? street, String? area, String? city, String? state, String? pincode}) => Place(
        latitude: latitude,
        longitude: longitude,
        street: street ?? this.street,
        area: area ?? this.area,
        city: city ?? this.city,
        state: state ?? this.state,
        pincode: pincode ?? this.pincode,
      );
}
