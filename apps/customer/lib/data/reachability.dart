import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the API could be reached the last time the app tried. Starts true. A connection failure or timeout
/// turns it false; any answer from the server (even an error) turns it true again.
///
/// This is what the "You're offline" banner reads. It is learned from real requests, so it needs no extra permission
/// and never says "offline" because of a flaky Wi-Fi icon while the API is actually fine.
class Reachability extends Notifier<bool> {
  @override
  bool build() => true;

  void reached() {
    if (!state) state = true;
  }

  void lost() {
    if (state) state = false;
  }
}

final reachabilityProvider = NotifierProvider<Reachability, bool>(Reachability.new);

/// Reports every request's outcome to [Reachability].
class ReachabilityInterceptor extends Interceptor {
  ReachabilityInterceptor(this._report);

  final void Function(bool reached) _report;

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _report(true);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        _report(false);
      case DioExceptionType.badResponse:
        _report(true);
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        break;
    }
    handler.next(err);
  }
}
