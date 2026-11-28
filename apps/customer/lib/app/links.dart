import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/analytics/analytics.dart';
import '../features/basket/basket.dart';
import 'routes.dart';

/// The website's hosts. Links to them open in the app (Android App Links, iOS Universal Links).
const linkHosts = {'irondost.in', 'www.irondost.in'};

/// Where a link should take the customer.
sealed class LinkTarget {
  const LinkTarget();
}

/// A screen in the app, with anything the link carried that the app keeps.
final class AppLink extends LinkTarget {
  const AppLink(this.route, {this.src, this.campaign, this.referralCode});

  final String route;

  /// From `/get?src=ig&c=<campaign>`.
  final String? src;
  final String? campaign;

  /// From `/r/<code>`.
  final String? referralCode;

  @override
  bool operator ==(Object other) =>
      other is AppLink && other.route == route && other.src == src && other.campaign == campaign && other.referralCode == referralCode;

  @override
  int get hashCode => Object.hash(route, src, campaign, referralCode);

  @override
  String toString() => 'AppLink($route)';
}

/// A web page, opened in the browser.
final class WebLink extends LinkTarget {
  const WebLink(this.uri);
  final Uri uri;

  @override
  bool operator ==(Object other) => other is WebLink && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() => 'WebLink($uri)';
}

/// What [raw] points at: an in-app path (`/offers`, `/orders/<id>`, `/catalogue`, `/basket`…), an irondost.in link for
/// one of those, or any other `https://` page. Null for anything else (blank, `javascript:`, a path the app does not know).
LinkTarget? resolveLink(String? raw) {
  final text = raw?.trim();
  if (text == null || text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  if (uri == null) return null;
  if (uri.scheme == 'https' || uri.scheme == 'http') {
    if (linkHosts.contains(uri.host.toLowerCase())) return appLinkFor(uri) ?? WebLink(uri);
    return uri.scheme == 'https' ? WebLink(uri) : null;
  }
  if (uri.hasScheme || !text.startsWith('/')) return null;
  return appLinkFor(uri);
}

/// The screen for a website or in-app path, or null when the app has none.
AppLink? appLinkFor(Uri uri) {
  final parts = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  final q = uri.queryParameters;
  String? id(int i) => parts.length > i && parts[i].trim().isNotEmpty ? parts[i].trim() : null;
  final first = parts.firstOrNull;
  switch (first) {
    case null:
      return const AppLink(Routes.home);
    case 'get':
      return AppLink(Routes.home, src: q['src'], campaign: q['c']);
    case 'r':
      final code = id(1);
      return code == null ? const AppLink(Routes.home) : AppLink(Routes.home, referralCode: code);
    case 'o' || 'order' || 'orders':
      final orderId = id(1);
      if (orderId == null) return const AppLink(Routes.orders);
      return AppLink(Routes.order(orderId));
    case 'offers':
      return const AppLink(Routes.offers);
    case 'catalogue' || 'book' || 'prices':
      final service = q['service'];
      return AppLink(service == null || service.isEmpty ? Routes.book : '${Routes.book}?service=${Uri.encodeQueryComponent(service)}');
    case 'basket':
      return const AppLink(Routes.basket);
    case 'home':
      return const AppLink(Routes.home);
    case 'account':
      return const AppLink(Routes.account);
    case 'notifications':
      return const AppLink(Routes.notifications);
    case 'help' || 'support':
      return const AppLink(Routes.help);
    case 'reports':
      final issueId = id(1);
      return AppLink(issueId == null ? Routes.issues : Routes.issue(issueId));
  }
  return null;
}

/// The tab roots: links to these switch tab instead of stacking a screen.
bool isTabRoute(String route) {
  final path = route.split('?').first;
  return path == Routes.home || path == Routes.orders || path == Routes.basket || path == Routes.account;
}

// ── Referral ───────────────────────────────────────────────────────────────

const _referralKey = 'referral.code.v1';

/// The referral code from the last irondost.in/r/<code> link, kept for checkout to send once the API takes one.
final referralCodeProvider = NotifierProvider<ReferralCode, String?>(ReferralCode.new);

class ReferralCode extends Notifier<String?> {
  @override
  String? build() => ref.read(sharedPreferencesProvider).getString(_referralKey);

  void save(String code) {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty || clean.length > 32 || !RegExp(r'^[A-Z0-9_-]+$').hasMatch(clean)) return;
    state = clean;
    unawaited(ref.read(sharedPreferencesProvider).setString(_referralKey, clean));
  }

  /// After checkout has used it.
  void clear() {
    state = null;
    unawaited(ref.read(sharedPreferencesProvider).remove(_referralKey));
  }
}

/// Turns links (from a notification, the inbox or the website) into somewhere to go, keeping what they carried: the
/// source and campaign as analytics user properties, the referral code for checkout.
final linkOpenerProvider = Provider<LinkOpener>(LinkOpener.new);

class LinkOpener {
  LinkOpener(this._ref);
  final Ref _ref;

  /// The in-app route or `https://` URL for [raw], or null when it points nowhere the app can go.
  String? targetFor(String? raw) {
    final target = resolveLink(raw);
    switch (target) {
      case null:
        return null;
      case WebLink(:final uri):
        return uri.toString();
      case AppLink():
        capture(target);
        return target.route;
    }
  }

  void capture(AppLink link) {
    if (link.src != null || link.campaign != null) {
      _ref.read(analyticsProvider).recordSource(src: link.src, campaign: link.campaign);
    }
    if (link.referralCode != null) _ref.read(referralCodeProvider.notifier).save(link.referralCode!);
  }
}

// ── Opening links ──────────────────────────────────────────────────────────

/// Where the app should go next because of a link or a tapped notification: an in-app route, or an `https://` URL for
/// the browser. The tabs act on it as soon as they are on screen (after sign-in, if a link arrived before it).
final pendingLinkProvider = NotifierProvider<PendingLink, String?>(PendingLink.new);

class PendingLink extends Notifier<String?> {
  @override
  String? build() => null;

  void open(String target) => state = target;
  void done() => state = null;
}

/// Where incoming website links come from. app_links in the app; a script in tests.
abstract class LinkSource {
  Future<Uri?> initial();
  Stream<Uri> get stream;
}

class AppLinksSource implements LinkSource {
  AppLinksSource();
  final _links = AppLinks();

  @override
  Future<Uri?> initial() => _links.getInitialLink();

  @override
  Stream<Uri> get stream => _links.uriLinkStream;
}

final linkSourceProvider = Provider<LinkSource>((_) => AppLinksSource());

/// Listens for irondost.in links for the whole life of the app. Other URLs (the Firebase phone-check callback, Google
/// sign-in) are left alone. Watched by the app at start.
final deepLinkListenerProvider = Provider<void>((ref) {
  // app_links also sends the link that launched the app down its stream: the same link twice in a moment is one tap.
  Uri? last;
  DateTime? lastAt;
  void handle(Uri uri) {
    if (!linkHosts.contains(uri.host.toLowerCase())) return;
    final now = DateTime.now();
    if (uri == last && lastAt != null && now.difference(lastAt!) < const Duration(seconds: 5)) return;
    last = uri;
    lastAt = now;
    if (resolveLink(uri.toString()) is! AppLink) return; // a page the app has no screen for stays on the website
    final route = ref.read(linkOpenerProvider).targetFor(uri.toString());
    if (route != null) ref.read(pendingLinkProvider.notifier).open(route);
  }

  LinkSource source;
  try {
    source = ref.watch(linkSourceProvider);
  } catch (e) {
    debugPrint('links: unavailable ($e)');
    return;
  }
  StreamSubscription<Uri>? sub;
  try {
    sub = source.stream.listen(handle, onError: (Object e) => debugPrint('links: $e'));
  } catch (e) {
    debugPrint('links: no stream ($e)');
  }
  ref.onDispose(() => sub?.cancel());
  unawaited(
    Future(source.initial).then((uri) {
      if (uri != null) handle(uri);
    }, onError: (Object e) => debugPrint('links: no initial link ($e)')),
  );
});
