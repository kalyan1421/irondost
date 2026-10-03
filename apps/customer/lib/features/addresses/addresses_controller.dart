import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_client.dart';
import '../auth/session.dart';
import 'address_repository.dart';

/// The signed-in customer's saved addresses, primary first. Empty while signed out.
final addressesProvider = AsyncNotifierProvider<AddressesController, List<AddressDto>>(AddressesController.new);

class AddressesController extends AsyncNotifier<List<AddressDto>> {
  @override
  Future<List<AddressDto>> build() async {
    // Starts over whenever the session changes (sign-in, profile saved, sign-out).
    final session = ref.watch(sessionProvider).value;
    if (session is! SignedIn) return const [];
    return ref.read(addressRepositoryProvider).list();
  }

  AddressRepository get _repo => ref.read(addressRepositoryProvider);

  Future<List<AddressDto>> _reload() async {
    final list = await _repo.list();
    state = AsyncData(list);
    return list;
  }

  Future<AddressDto> add(CreateAddressDto dto) async {
    final created = await _repo.create(dto);
    await _reload();
    return created;
  }

  Future<AddressDto> edit(String id, UpdateAddressDto dto) async {
    final updated = await _repo.update(id, dto);
    await _reload();
    return updated;
  }

  Future<void> remove(String id) async {
    await _repo.remove(id);
    final selected = ref.read(selectedAddressIdProvider);
    if (selected == id) ref.read(selectedAddressIdProvider.notifier).select(null);
    await _reload();
  }
}

/// Which address the customer is booking from. Null means "the primary one".
final selectedAddressIdProvider = NotifierProvider<SelectedAddressId, String?>(SelectedAddressId.new);

class SelectedAddressId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

/// The address orders will be picked up from: the one the customer chose, else the primary.
final selectedAddressProvider = Provider<AddressDto?>((ref) {
  final list = ref.watch(addressesProvider).value;
  if (list == null || list.isEmpty) return null;
  final id = ref.watch(selectedAddressIdProvider);
  return list.firstWhere((a) => a.id == id, orElse: () => list.firstWhere((a) => a.isPrimary, orElse: () => list.first));
});
