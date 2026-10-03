import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../startup/startup.dart';

/// How customers reach IronDost. The API's /v1/config is the source; the fallback is used
/// only when the API itself can't be reached.
class Support {
  const Support({required this.phone, this.email});

  final String phone;
  final String? email;

  static const fallbackPhone = '+919063290012';

  static Support of(WidgetRef ref) {
    final config = ref.read(startupProvider).value?.config;
    return Support(phone: config?.supportPhone ?? fallbackPhone, email: config?.supportEmail);
  }

  static Future<void> dial(String phone) => launchUrl(Uri(scheme: 'tel', path: phone));

  static Future<void> mail(String address) => launchUrl(Uri(scheme: 'mailto', path: address));
}
