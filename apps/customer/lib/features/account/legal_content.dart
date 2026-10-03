import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'legal_data.g.dart';

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

/// The policy text, from `packages/legal/legal.json` (shared with the website; regenerate with `dart run tool/gen_legal.dart`).
/// It was drafted from the previous Cloud Ironing Factory app's policies and updated for what IronDost does; it should be
/// read by whoever is responsible for the business before release.
abstract final class LegalContent {
  static const company = legalCompany;
  static const updated = legalUpdated;

  /// The line under every policy's title.
  static const byline = 'IronDost is run by $company. Last updated $updated.';

  static const terms = legalTerms;
  static const privacy = legalPrivacy;
  static const cancellation = legalCancellation;
}
