import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The three policies customers can read in the app.
enum LegalDoc {
  terms('terms', 'Terms of service', LucideIcons.fileText),
  privacy('privacy', 'Privacy policy', LucideIcons.shieldCheck),
  cancellation('cancellation', 'Cancellation & refunds', LucideIcons.refreshCw);

  const LegalDoc(this.slug, this.menuLabel, this.icon);

  /// Used in the route: `/legal/terms`.
  final String slug;
  final String menuLabel;
  final IconData icon;

  static LegalDoc? fromSlug(String? slug) => values.where((d) => d.slug == slug).firstOrNull;

  LegalPage get page => switch (this) {
        terms => LegalContent.terms,
        privacy => LegalContent.privacy,
        cancellation => LegalContent.cancellation,
      };
}

class LegalSection {
  const LegalSection(this.heading, {this.paragraphs = const [], this.bullets = const []});

  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;
}

class LegalPage {
  const LegalPage({required this.title, required this.sections});

  final String title;
  final List<LegalSection> sections;
}

/// The policy text. Drafted from the previous Cloud Ironing Factory app's policies and updated for
/// what IronDost does; it should be read by whoever is responsible for the business before release.
abstract final class LegalContent {
  static const company = 'Cloud Ironing Factory Private Limited';
  static const updated = 'October 2026';

  /// The line under every policy's title.
  static const byline = 'IronDost is run by $company. Last updated $updated.';

  static const terms = LegalPage(
    title: 'Terms of service',
    sections: [
      LegalSection(
        '1. Using IronDost',
        paragraphs: [
          'These terms are an agreement between you and $company ("we", "us"). By creating an account or placing an order you agree to them.',
          'You sign in with your mobile number. Keep your phone secure: orders placed from your account are treated as yours.',
        ],
      ),
      LegalSection(
        '2. Services and prices',
        paragraphs: [
          'We collect your clothes, iron, wash or dry-clean them as you chose, and deliver them back. Prices, any pickup and delivery fee, and the pickup and delivery windows are shown before you confirm an order.',
          'Delivery takes about 20 hours or more from pickup, depending on the service and our workload. The delivery window you pick is our target, not a guarantee.',
          'You give a rough count of items when you book. Your pickup partner counts them at pickup, and the bill follows that count.',
        ],
      ),
      LegalSection(
        '3. Paying',
        paragraphs: ['Pay online (UPI, cards or netbanking, processed by Razorpay) or in cash at delivery. The full amount is due by the time your clothes are delivered.'],
      ),
      LegalSection(
        '4. Looking after your clothes',
        paragraphs: ['We take reasonable care of your garments.'],
        bullets: [
          'Tell us about stains, delicate fabrics and expensive embellishments when you hand over your clothes.',
          'We are not responsible for damage that was already there, defects in the fabric, or ordinary wear and tear.',
          'We may refuse items that need specialist handling beyond what we offer.',
          'Report any damage or missing item within 48 hours of delivery. We will inspect it and offer a repair, a replacement or a refund.',
          'Our liability for a lost or damaged item is limited to the value agreed with you, or the garment\'s market value if nothing was agreed.',
        ],
      ),
      LegalSection(
        '5. Cancelling and refunds',
        paragraphs: ['Cancelling and refunds are covered in the cancellation and refund policy, which is part of these terms.'],
      ),
      LegalSection(
        '6. Changes and contact',
        paragraphs: [
          'We may update these terms. The date at the top says when they last changed, and using IronDost after a change means you accept it.',
          'These terms are governed by the laws of India. The courts in Chennai have exclusive jurisdiction over any dispute.',
        ],
      ),
    ],
  );

  static const privacy = LegalPage(
    title: 'Privacy policy',
    sections: [
      LegalSection(
        '1. What we collect',
        paragraphs: ['We collect only what we need to collect, clean and deliver your clothes and to talk to you about your orders.'],
        bullets: [
          'Your mobile number (to sign you in) and your name. Your email, if you add one, for receipts.',
          'Your saved addresses, including the point you place on the map. If you tap "use my current location", your phone\'s location is used once to fill in the address; we do not track you in the background.',
          'Your orders: items, prices, pickup and delivery times, and whether they are paid.',
          'A notification token for your phone, so we can send order updates if you allow notifications.',
        ],
      ),
      LegalSection(
        '2. How we use it',
        paragraphs: [
          'To place and deliver your orders, send you updates, take payments, give you support and keep our service safe. We do not sell your data and we do not use advertising trackers.',
          'Your pickup and delivery partners see your name, phone number and address for the orders they handle, and nothing else.',
        ],
      ),
      LegalSection(
        '3. Who else handles it',
        paragraphs: ['A few services process data for us:'],
        bullets: [
          'Google Firebase sends your sign-in code by SMS and delivers notifications.',
          'Razorpay processes online payments. Your card or UPI details go to Razorpay, not to us.',
          'Google Maps shows the map when you choose an address.',
        ],
      ),
      LegalSection(
        '4. Keeping it safe',
        paragraphs: ['We protect your information with access controls and encrypted connections. No system is perfectly secure, so please tell us at once if you think your account was used by someone else.'],
      ),
      LegalSection(
        '5. Your choices',
        paragraphs: [
          'You can change your name and email in Account, and your addresses under Saved addresses. You can turn notifications off in your phone\'s settings.',
          'To delete your account, go to Account and tap Delete account (you need to have no orders in progress). We then remove your name, number, email and addresses. Past orders stay in our records without your details, because we must keep them for accounts and tax.',
        ],
      ),
      LegalSection(
        '6. Contact',
        paragraphs: ['Questions about your data? Call or email us from Help and support. This policy is governed by the laws of India.'],
      ),
    ],
  );

  static const cancellation = LegalPage(
    title: 'Cancellation and refunds',
    sections: [
      LegalSection(
        '1. Paying for your order',
        paragraphs: ['Pay online (UPI, cards or netbanking) or in cash at delivery. The full amount is due by the time your clothes are delivered.'],
      ),
      LegalSection(
        '2. Cancelling',
        bullets: [
          'Before pickup: cancel free in the app. Anything you paid online is refunded in full.',
          'After pickup, before ironing starts: call us and we\'ll cancel with a full refund.',
          'Once ironing has started: the order can\'t be cancelled or refunded.',
        ],
      ),
      LegalSection(
        '3. Refunds',
        paragraphs: ['We refund when we couldn\'t provide the service, or as agreed when we resolve a complaint. Approved refunds reach the payment method you used within 7–14 business days.'],
      ),
    ],
  );
}
