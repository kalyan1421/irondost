import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:irondost_customer/features/addresses/place.dart';

void main() {
  test('reads an iOS-style placemark', () {
    final place = Place.fromPlacemark(
      const Placemark(thoroughfare: 'Road No. 12', subLocality: 'Banjara Hills', locality: 'Hyderabad', administrativeArea: 'Telangana', postalCode: '500034'),
      latitude: 17.4126,
      longitude: 78.4482,
    );
    expect(place.title, 'Road No. 12, Banjara Hills');
    expect(place.subtitle, 'Hyderabad, Telangana 500034');
    expect(place.isComplete, isTrue);
  });

  test('falls back to name and drops invalid PIN codes', () {
    final place = Place.fromPlacemark(
      const Placemark(name: 'KBR Park', locality: ' Hyderabad ', administrativeArea: 'Telangana', postalCode: '5000'),
      latitude: 0,
      longitude: 0,
    );
    expect(place.street, 'KBR Park');
    expect(place.city, 'Hyderabad');
    expect(place.pincode, isNull);
    expect(place.isComplete, isFalse);
  });

  test('does not repeat the neighbourhood as the street', () {
    final place = Place.fromPlacemark(
      const Placemark(name: 'Banjara Hills', subLocality: 'Banjara Hills', locality: 'Hyderabad', administrativeArea: 'Telangana', postalCode: '500034'),
      latitude: 17.4126,
      longitude: 78.4482,
    );
    expect(place.street, 'Banjara Hills');
    expect(place.area, isNull);
    expect(place.title, 'Banjara Hills');
  });

  test('accepts a PIN code with a space', () {
    final place = Place.fromPlacemark(const Placemark(postalCode: '500 034'), latitude: 0, longitude: 0);
    expect(place.pincode, '500034');
  });

  test('describes a bare pin without crashing', () {
    const place = Place(latitude: 17.4, longitude: 78.4);
    expect(place.title, 'Selected location');
    expect(place.subtitle, '');
  });
}
