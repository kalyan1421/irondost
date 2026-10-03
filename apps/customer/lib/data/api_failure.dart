import 'package:dio/dio.dart';

enum ApiFailureKind {
  /// No connection, DNS failure or the request never reached the server.
  offline,

  /// The server took too long.
  timeout,

  /// 5xx: the API or something behind it is down.
  server,

  /// 401: the sign-in is no longer valid.
  unauthorized,

  /// Any other 4xx: the API refused the request; [ApiFailure.code] says why.
  rejected,
}

/// An API error the UI can branch on. The API answers with `{ statusCode, code, message, details? }`.
class ApiFailure implements Exception {
  const ApiFailure(this.kind, {this.statusCode, this.code, this.message, this.details});

  final ApiFailureKind kind;
  final int? statusCode;
  final String? code;
  final String? message;
  final Map<String, Object?>? details;

  bool get isConnectivity => kind == ApiFailureKind.offline || kind == ApiFailureKind.timeout;

  factory ApiFailure.from(Object error) {
    if (error is ApiFailure) return error;
    if (error is! DioException) return ApiFailure(ApiFailureKind.server, message: error.toString());
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiFailure(ApiFailureKind.timeout);
      case DioExceptionType.connectionError:
        return const ApiFailure(ApiFailureKind.offline);
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        final body = error.response?.data;
        final map = body is Map ? body.cast<String, Object?>() : const <String, Object?>{};
        final message = map['message'];
        return ApiFailure(
          status >= 500
              ? ApiFailureKind.server
              : status == 401
                  ? ApiFailureKind.unauthorized
                  : ApiFailureKind.rejected,
          statusCode: status,
          code: map['code'] as String?,
          message: message is List ? message.join('\n') : message as String?,
          details: (map['details'] as Map?)?.cast<String, Object?>(),
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return error.error is ApiFailure
            ? error.error! as ApiFailure
            : const ApiFailure(ApiFailureKind.offline);
    }
  }

  @override
  String toString() => 'ApiFailure($kind, $statusCode, $code, $message)';
}
