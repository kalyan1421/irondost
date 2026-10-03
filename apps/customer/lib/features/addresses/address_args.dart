import '../../data/api_client.dart';
import 'place.dart';

enum PinMode {
  /// Pick a spot, then fill in the details and save a new address.
  newAddress,

  /// Move an existing address: confirming returns the new [Place] to the form.
  changeLocation,
}

class PinArgs {
  const PinArgs({this.initial, this.mode = PinMode.newAddress, this.onboarding = false, this.returnTo});

  final Place? initial;
  final PinMode mode;

  /// First-run setup: step 2 of 2, no back button.
  final bool onboarding;

  /// Where to go after saving (defaults to Home).
  final String? returnTo;
}

/// What the address form edits: the geocoded place, or an existing saved address.
class AddressDraft {
  const AddressDraft({
    this.latitude,
    this.longitude,
    this.street,
    this.area,
    this.city,
    this.state,
    this.pincode,
    this.houseNo = '',
    this.building = '',
    this.landmark = '',
    this.label = 'Home',
    this.isPrimary = false,
  });

  factory AddressDraft.fromPlace(Place p) => AddressDraft(
        latitude: p.latitude,
        longitude: p.longitude,
        street: p.street,
        area: p.area,
        city: p.city,
        state: p.state,
        pincode: p.pincode,
      );

  factory AddressDraft.fromAddress(AddressDto a) => AddressDraft(
        latitude: a.latitude?.toDouble(),
        longitude: a.longitude?.toDouble(),
        street: a.street,
        area: a.area,
        city: a.city,
        state: a.state,
        pincode: a.pincode,
        houseNo: a.houseNo,
        building: a.building ?? '',
        landmark: a.landmark ?? '',
        label: a.label,
        isPrimary: a.isPrimary,
      );

  final double? latitude;
  final double? longitude;
  final String? street;
  final String? area;
  final String? city;
  final String? state;
  final String? pincode;
  final String houseNo;
  final String building;
  final String landmark;
  final String label;
  final bool isPrimary;

  /// Same details at a new map position.
  AddressDraft movedTo(Place p) => AddressDraft(
        latitude: p.latitude,
        longitude: p.longitude,
        street: p.street ?? street,
        area: p.area ?? area,
        city: p.city ?? city,
        state: p.state ?? state,
        pincode: p.pincode ?? pincode,
        houseNo: houseNo,
        building: building,
        landmark: landmark,
        label: label,
        isPrimary: isPrimary,
      );

  /// "Road No. 12, Banjara Hills".
  String get title => [?street, if (area != null && area != street) area!].join(', ');

  String get subtitle => [
        [?city, ?state].join(', '),
        ?pincode,
      ].where((s) => s.isNotEmpty).join(' ');
}

class FormArgs {
  const FormArgs({required this.draft, this.existingId, this.onboarding = false, this.returnTo});

  final AddressDraft draft;

  /// Set when editing a saved address.
  final String? existingId;
  final bool onboarding;
  final String? returnTo;
}
