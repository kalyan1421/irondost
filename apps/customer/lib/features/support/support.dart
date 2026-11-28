import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../design/theme.dart';
import '../../design/widgets/id_button.dart';
import '../../design/widgets/id_sheet.dart';
import '../startup/startup.dart';

/// Opens a URL outside the app. Web links (WhatsApp, campaign pages) go to their own app or the browser.
final supportLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (_) => (uri) => launchUrl(uri, mode: uri.scheme == 'https' || uri.scheme == 'http' ? LaunchMode.externalApplication : LaunchMode.platformDefault),
);

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

  /// A WhatsApp chat with [phone] (any Indian format), the message box already holding [message].
  static Uri whatsappUri(String phone, {String? message}) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) digits = '91$digits';
    if (digits.length == 11 && digits.startsWith('0')) digits = '91${digits.substring(1)}';
    // Spaces as %20: WhatsApp shows a form-encoded "+" literally.
    return Uri.parse('https://wa.me/$digits${message == null || message.isEmpty ? '' : '?text=${Uri.encodeComponent(message)}'}');
  }

  /// What the chat starts with: the order number to quote, or nothing in particular.
  static String whatsappMessage({String? orderNumber}) => orderNumber == null ? 'Hi IronDost, ' : 'Order $orderNumber: ';

  static Future<void> whatsapp(String phone, {required BuildContext context, Support? fallback, String? orderNumber}) =>
      _open(whatsappUri(phone, message: whatsappMessage(orderNumber: orderNumber)), context, fallback);

  static Future<void> _open(Uri uri, BuildContext context, Support? fallback) async {
    var opened = false;
    try { opened = await ProviderScope.containerOf(context, listen: false).read(supportLauncherProvider)(uri); }
    catch (_) { /* Missing applications and platform failures share the same recoverable UI. */ }
    if (opened || !context.mounted) return;
    await showIdSheet<void>(context, builder: (sheet) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Text(switch (uri.scheme) { 'tel' => "Couldn't open the phone app", 'mailto' => "Couldn't open the email app", _ => "Couldn't open WhatsApp" }, style: sheet.text.titleLg),
      const SizedBox(height: IdSpace.s3),
      const Text('Copy the contact and use another app, or try the other support channel.'),
      SelectableText(_contact(uri), style: sheet.text.bodyLg),
      IdButton.outline(label: 'Copy contact', onPressed: () async {
        await Clipboard.setData(ClipboardData(text: _contact(uri)));
        if (sheet.mounted) ScaffoldMessenger.of(sheet).showSnackBar(const SnackBar(content: Text('Contact copied')));
      }),
      if (uri.scheme == 'tel' && fallback?.email != null) IdButton.text(label: 'Email support', onPressed: () { Navigator.of(sheet).pop(); mail(fallback!.email!, context: context, fallback: fallback); }),
      if (uri.scheme != 'tel' && fallback != null) IdButton.text(label: 'Call support', onPressed: () { Navigator.of(sheet).pop(); dial(fallback.phone, context: context, fallback: fallback); }),
      IdButton.text(label: 'Close', onPressed: () => Navigator.of(sheet).pop()),
    ]));
  }

  /// The number or address to copy: wa.me links show the number.
  static String _contact(Uri uri) => uri.host == 'wa.me' ? '+${uri.pathSegments.firstOrNull ?? ''}' : uri.path;
}
