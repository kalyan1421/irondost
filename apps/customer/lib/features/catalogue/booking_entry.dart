import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../addresses/addresses_controller.dart';
import '../addresses/addresses_screen.dart';

/// Retains the serviceability gate and the selected service tab.
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
            'We don’t pick up from ${address.area ?? address.city} yet. Choose another address.',
          ),
        ),
      );
    showAddressPicker(context);
    return;
  }
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
