import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../addresses/addresses_controller.dart';
import '../addresses/addresses_screen.dart';
import 'laundry.dart';

/// Retains the serviceability gate and the selected service tab. With no service named, the price list opens on
/// Laundry, the main service.
void startBooking(
  BuildContext context,
  WidgetRef ref, {
  String? service,
  bool search = false,
}) {
  final address = ref.read(selectedAddressProvider);
  if (address == null) {
    context.push(Routes.addressPin);
    return;
  }
  if (!address.serviceable) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'We’re not in ${address.area ?? address.city} yet. Choose another address to book.',
          ),
        ),
      );
    showAddressPicker(context);
    return;
  }
  service ??= search ? null : ref.read(laundrySlugProvider);
  context.push(
    search
        ? Routes.bookSearch
        : service == null
        ? Routes.book
        : Uri(
            path: Routes.book,
            queryParameters: {'service': service},
          ).toString(),
  );
}
