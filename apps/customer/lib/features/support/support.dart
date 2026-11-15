import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_sheet.dart';
import '../startup/startup.dart';

final supportLauncherProvider = Provider<Future<bool> Function(Uri)>((_) => (uri) => launchUrl(uri));

class Support {
  const Support({required this.phone, this.email});
  final String phone;
  final String? email;
  static const fallbackPhone = '+919063290012';
  static Support of(WidgetRef ref) {
    final config = ref.read(startupProvider).value?.config;
    return Support(phone: config?.supportPhone ?? fallbackPhone, email: config?.supportEmail);
  }

  static Future<void> dial(String phone, {required BuildContext context, Support? fallback}) => _open(Uri(scheme: 'tel', path: phone), context, fallback);
  static Future<void> mail(String address, {required BuildContext context, Support? fallback, String? orderNumber}) {
    final query = orderNumber == null ? null : {'subject': 'Help with order $orderNumber', 'body': 'Order: $orderNumber\n\nPlease describe the problem:\n'}
      .entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
    return _open(Uri(scheme: 'mailto', path: address, query: query), context, fallback);
  }

  static Future<void> _open(Uri uri, BuildContext context, Support? fallback) async {
    var opened = false;
    try { opened = await ProviderScope.containerOf(context, listen: false).read(supportLauncherProvider)(uri); }
    catch (_) { /* Missing applications and platform failures share the same recoverable UI. */ }
    if (opened || !context.mounted) return;
    await showIdSheet<void>(context, builder: (sheet) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Text(uri.scheme == 'tel' ? "Couldn't open the phone app" : "Couldn't open the email app", style: sheet.text.titleLg),
      const SizedBox(height: IdSpace.s3),
      const Text('Copy the contact and use another app, or try the other support channel.'),
      SelectableText(uri.path, style: sheet.text.bodyLg),
      IdButton.outline(label: 'Copy contact', onPressed: () async {
        await Clipboard.setData(ClipboardData(text: uri.path));
        if (sheet.mounted) ScaffoldMessenger.of(sheet).showSnackBar(const SnackBar(content: Text('Contact copied')));
      }),
      if (uri.scheme == 'tel' && fallback?.email != null) IdButton.text(label: 'Email support', onPressed: () { Navigator.of(sheet).pop(); mail(fallback!.email!, context: context, fallback: fallback); }),
      if (uri.scheme == 'mailto' && fallback != null) IdButton.text(label: 'Call support', onPressed: () { Navigator.of(sheet).pop(); dial(fallback.phone, context: context, fallback: fallback); }),
      IdButton.text(label: 'Close', onPressed: () => Navigator.of(sheet).pop()),
    ]));
  }
}
