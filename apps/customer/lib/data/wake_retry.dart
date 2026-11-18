import 'api_failure.dart';

/// Tries again while the API is waking up.
///
/// On a sleeping host the first request waits a minute or so, or is answered 502, 503 or 504, and the call times out after
/// 20 seconds. Without a retry the very first open of the app shows "We'll be right back", which is what App Review saw.
/// Only timeouts and those three gateway answers are retried; offline, a refusal (4xx) or a real server error (500) is
/// returned at once, because waiting will not change it.
abstract final class WakeRetry {
  /// How many times the call is made in all.
  static const attempts = 4;

  /// The pause between calls. Tests set it to zero.
  static Duration delay = const Duration(seconds: 2);

  static bool _waking(ApiFailure f) =>
      f.kind == ApiFailureKind.timeout || (f.kind == ApiFailureKind.server && const {502, 503, 504}.contains(f.statusCode));

  static Future<T> run<T>(Future<T> Function() call) async {
    for (var attempt = 1;; attempt++) {
      try {
        return await call();
      } catch (error) {
        if (attempt >= attempts || !_waking(ApiFailure.from(error))) rethrow;
        await Future<void>.delayed(delay);
      }
    }
  }
}
