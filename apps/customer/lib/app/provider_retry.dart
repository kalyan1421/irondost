/// Riverpod retries a failed provider by itself, backing off for about a minute. Offline, that would
/// leave the launch spinner up instead of the "no connection" screen. Every screen has its own
/// "Try again", so nothing retries silently.
Duration? noAutomaticRetry(int retryCount, Object error) => null;
