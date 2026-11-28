import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_install_referrer/play_install_referrer.dart';

import '../../app/links.dart';
import '../basket/basket.dart';

/// The booking funnel, in the order a new customer moves through it. Names are what Firebase shows.
abstract final class Funnel {
  static const appOpen = 'app_open';
  static const addressSaved = 'address_saved';
  static const basketStarted = 'basket_started';
  static const slotPicked = 'slot_picked';
  static const orderPlaced = 'order_placed';
  static const orderDelivered = 'order_delivered';
  static const secondOrder = 'second_order';
}

/// Where analytics events go. Firebase in the app; tests record them.
abstract class AnalyticsSink {
  Future<void> log(String name, [Map<String, Object> params = const {}]);
  Future<void> setUserProperty(String name, String? value);
}

/// Firebase Analytics. Every call swallows its own failure: measuring must never break booking.
class FirebaseAnalyticsSink implements AnalyticsSink {
  const FirebaseAnalyticsSink();

  /// False in tests and anywhere Firebase did not start.
  static bool get _ready {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> log(String name, [Map<String, Object> params = const {}]) async {
    if (!_ready) return;
    try {
      final fa = FirebaseAnalytics.instance;
      if (name == Funnel.appOpen) {
        await fa.logAppOpen();
      } else {
        await fa.logEvent(name: name, parameters: params.isEmpty ? null : params);
      }
    } catch (e) {
      debugPrint('analytics: $name not logged ($e)');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    if (!_ready) return;
    try {
      await FirebaseAnalytics.instance.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('analytics: user property $name not set ($e)');
    }
  }
}

final analyticsSinkProvider = Provider<AnalyticsSink>((_) => const FirebaseAnalyticsSink());

/// Logging the funnel from anywhere in the app: `ref.read(analyticsProvider).log(Funnel.orderPlaced)`.
final analyticsProvider = Provider<Analytics>(Analytics.new);

class Analytics {
  Analytics(this._ref);
  final Ref _ref;

  AnalyticsSink get _sink => _ref.read(analyticsSinkProvider);

  void log(String name, [Map<String, Object> params = const {}]) => unawaited(_sink.log(name, params));

  /// Where the customer came from: `src` (ig, wa, flyer…) and `c` (the campaign), from an irondost.in/get link or
  /// the Play Store install referrer. The first source seen is kept; a later link with a campaign updates `c`.
  void recordSource({String? src, String? campaign}) {
    final s = _clean(src);
    final c = _clean(campaign);
    if (s != null) unawaited(_sink.setUserProperty('src', s));
    if (c != null) unawaited(_sink.setUserProperty('c', c));
  }

  /// Firebase user property values are at most 36 characters.
  static String? _clean(String? v) {
    final t = v?.trim();
    if (t == null || t.isEmpty) return null;
    return t.length > 36 ? t.substring(0, 36) : t;
  }
}

/// `src` and `c` from an install referrer string such as `src=ig&c=diwali` (also `utm_source` / `utm_campaign`).
({String? src, String? campaign}) parseReferrer(String? referrer) {
  if (referrer == null || referrer.trim().isEmpty) return (src: null, campaign: null);
  Map<String, String> q;
  try {
    q = Uri.splitQueryString(referrer.trim().replaceFirst(RegExp(r'^\?'), ''));
  } catch (_) {
    return (src: null, campaign: null);
  }
  return (src: q['src'] ?? q['utm_source'], campaign: q['c'] ?? q['utm_campaign']);
}

/// Reads the Play Store install referrer. Null on iOS and wherever Play services are missing.
typedef InstallReferrerReader = Future<String?> Function();

final installReferrerReaderProvider = Provider<InstallReferrerReader>((_) => () async {
      if (!Platform.isAndroid) return null;
      return (await PlayInstallReferrer.installReferrer).installReferrer;
    });

const _referrerReadKey = 'analytics.referrer.read.v1';

/// Once per install: the app opened, and where the install came from. Watched by the app at start.
final appOpenAnalyticsProvider = FutureProvider<void>((ref) async {
  final analytics = ref.read(analyticsProvider)..log(Funnel.appOpen);
  final prefs = ref.read(sharedPreferencesProvider);
  if (prefs.getBool(_referrerReadKey) ?? false) return;
  try {
    final referrer = await ref.read(installReferrerReaderProvider)();
    final parsed = parseReferrer(referrer);
    analytics.recordSource(src: parsed.src, campaign: parsed.campaign);
    // irondost.in/r/<code> sends people without the app to the Play Store with utm_source=ref&utm_campaign=<code>.
    if (parsed.src == 'ref' && parsed.campaign != null) ref.read(referralCodeProvider.notifier).save(parsed.campaign!);
    await prefs.setBool(_referrerReadKey, true);
  } catch (e) {
    // No Play services, or the Play Store did not answer: try again next start.
    debugPrint('analytics: install referrer unavailable ($e)');
  }
});
