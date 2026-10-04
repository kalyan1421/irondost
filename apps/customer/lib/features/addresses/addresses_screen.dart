import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../data/api_client.dart';
import '../../design/theme.dart';
import '../../design/widgets/address_card.dart';
import '../../design/widgets/id_button.dart';
import 'address_args.dart';
import 'addresses_controller.dart';

/// Account → Saved addresses.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          tooltip: 'Back',
          onPressed: context.pop,
        ),
        title: const Text('Saved addresses'),
        shape: Border(bottom: BorderSide(color: c.border)),
      ),
      body: addresses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(IdSpace.s8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ApiFailure.from(e).isConnectivity
                      ? "You're offline. Check your connection."
                      : "Couldn't load your addresses.",
                  style: t.bodyLg.copyWith(color: c.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: IdSpace.s4),
                IdButton.tonal(
                  label: 'Try again',
                  onPressed: () => ref.invalidate(addressesProvider),
                ),
              ],
            ),
          ),
        ),
        data: (list) => RefreshIndicator(
          onRefresh: () => ref.refresh(addressesProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(IdSpace.s5),
            children: [
              for (final a in list) ...[
                AddressCard(
                  address: a,
                  onEdit: () => context.push(
                    Routes.addressDetails,
                    extra: FormArgs(
                      draft: AddressDraft.fromAddress(a),
                      existingId: a.id,
                      returnTo: Routes.addresses,
                    ),
                  ),
                ),
                const SizedBox(height: IdSpace.s3),
              ],
              IdButton.tonal(
                label: 'Add new address',
                icon: LucideIcons.plus,
                expand: true,
                onPressed: () => context.push(
                  Routes.addressPin,
                  extra: const PinArgs(returnTo: Routes.addresses),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Pick up from" sheet on Home. Addresses outside the service area stay listed but can't be chosen.
Future<void> showAddressPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (_) => const _AddressPickerSheet(),
  );
}

class _AddressPickerSheet extends ConsumerWidget {
  const _AddressPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    final list = ref.watch(addressesProvider).value ?? const <AddressDto>[];
    final selected = ref.watch(selectedAddressProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          IdSpace.s5,
          0,
          IdSpace.s5,
          IdSpace.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Pick up from', style: t.titleLg),
            ),
            const SizedBox(height: IdSpace.s4),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: IdSpace.s2),
                itemBuilder: (_, i) {
                  final a = list[i];
                  return AddressCard(
                    address: a,
                    selected: a.id == selected?.id,
                    onTap: a.serviceable
                        ? () {
                            ref
                                .read(selectedAddressIdProvider.notifier)
                                .select(a.id);
                            Navigator.pop(context);
                          }
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: IdSpace.s4),
            IdButton.tonal(
              label: 'Add new address',
              icon: LucideIcons.plus,
              expand: true,
              onPressed: () {
                Navigator.pop(context);
                unawaited(
                  context.push(Routes.addressPin, extra: const PinArgs()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
