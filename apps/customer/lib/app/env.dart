/// Build-time configuration, passed with `--dart-define-from-file=env/<name>.json`.
abstract final class AppEnv {
  /// Base URL of the IronDost API, without a trailing slash.
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:4000');

  /// `firebase` signs in with real SMS codes. `dev` skips Firebase and sends `dev:<phone>` tokens,
  /// which only an API running with AUTH_DEV_BYPASS=true accepts.
  static const authMode = String.fromEnvironment('AUTH_MODE', defaultValue: 'firebase');
  static bool get devAuth => authMode == 'dev';

  /// dev, staging or prod.
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  /// Whether the Google Maps SDK key is configured (ios/Flutter/Secrets.xcconfig and
  /// android/secrets.properties). Without it the pin screen offers search and current location only.
  static const mapsEnabled = bool.fromEnvironment('MAPS_ENABLED');

  /// What is wrong with this build's configuration for a store release, or null when it is fine. A release archived
  /// without `--dart-define-from-file=env/prod.json` would otherwise quietly point at localhost with dev sign-in.
  static String? get releaseProblem => problemFor(apiBaseUrl: apiBaseUrl, authMode: authMode, flavor: flavor);

  static String? problemFor({required String apiBaseUrl, required String authMode, required String flavor}) {
    if (flavor == 'dev') return 'FLAVOR is "dev"';
    if (authMode == 'dev') return 'AUTH_MODE is "dev"';
    if (!apiBaseUrl.startsWith('https://')) return 'API_BASE_URL is not an https address';
    return null;
  }
}
