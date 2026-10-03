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
}
