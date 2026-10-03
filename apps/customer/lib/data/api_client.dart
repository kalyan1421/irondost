import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/env.dart';
import '../features/auth/auth_repository.dart';
import 'api/export.dart';
import 'reachability.dart';

export 'api/export.dart';
export 'api_failure.dart';

/// Dio with the API base URL, timeouts and the signed-in user's bearer token.
final dioProvider = Provider<Dio>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnv.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors
    ..add(_AuthInterceptor(auth, dio))
    ..add(ReachabilityInterceptor((reached) {
      // Requests can finish after the app has torn the provider down (tests, sign-out); then there is nobody to tell.
      if (!ref.mounted) return;
      final state = ref.read(reachabilityProvider.notifier);
      reached ? state.reached() : state.lost();
    }));
  return dio;
});

/// The generated IronDost API client (see swagger_parser.yaml).
final apiProvider = Provider<IronDostApi>((ref) => IronDostApi(ref.watch(dioProvider)));

// A plain Interceptor, not a QueuedInterceptor: the retry below re-enters the chain, and a
// queued error handler would wait on itself if the retried request failed too.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._auth, this._dio);

  final AuthRepository _auth;
  final Dio _dio;
  static const _retried = 'auth-retried';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _auth.token();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  /// A Firebase ID token can expire between requests; refresh it once and retry.
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || options.extra[_retried] == true) return handler.next(err);
    final token = await _auth.token(forceRefresh: true);
    if (token == null) return handler.next(err);
    options
      ..headers['Authorization'] = 'Bearer $token'
      ..extra[_retried] = true;
    try {
      handler.resolve(await _dio.fetch<Object?>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
