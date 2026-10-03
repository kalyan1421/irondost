import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';
import 'place.dart';

/// Saved addresses and the service-area check, over the API.
abstract class AddressRepository {
  Future<List<AddressDto>> list();
  Future<AddressDto> create(CreateAddressDto dto);
  Future<AddressDto> update(String id, UpdateAddressDto dto);
  Future<void> remove(String id);

  /// Whether IronDost serves a place (map pin and/or PIN code).
  Future<ServiceAreaCheckDto> checkArea(Place place);
}

final addressRepositoryProvider = Provider<AddressRepository>((ref) => ApiAddressRepository(ref.watch(apiProvider)));

class ApiAddressRepository implements AddressRepository {
  ApiAddressRepository(this._api);
  final IronDostApi _api;

  @override
  Future<List<AddressDto>> list() => _api.addresses.addressesControllerList();

  @override
  Future<AddressDto> create(CreateAddressDto dto) => _api.addresses.addressesControllerCreate(body: dto);

  @override
  Future<AddressDto> update(String id, UpdateAddressDto dto) => _api.addresses.addressesControllerUpdate(id: id, body: dto);

  @override
  Future<void> remove(String id) => _api.addresses.addressesControllerRemove(id: id);

  @override
  Future<ServiceAreaCheckDto> checkArea(Place place) => _api.config.serviceAreaControllerCheck(
        latitude: place.latitude,
        longitude: place.longitude,
        pincode: place.pincode,
      );
}
