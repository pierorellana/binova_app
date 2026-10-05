enum FailureKind {
  network,
  unauthorized,
  validation,
  notFound,
  rateLimited,
  unavailable,
  unknown,
}

class AppFailure implements Exception {
  const AppFailure({
    required this.code,
    required this.message,
    required this.kind,
    this.statusCode,
    this.details = const <String, dynamic>{},
    this.traceId,
  });

  final String code;
  final String message;
  final FailureKind kind;
  final int? statusCode;
  final Map<String, dynamic> details;
  final String? traceId;

  factory AppFailure.network(Object error) {
    return AppFailure(
      code: 'NETWORK_UNAVAILABLE',
      message:
          'No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.',
      kind: FailureKind.network,
      details: <String, dynamic>{'cause': error.runtimeType.toString()},
    );
  }

  factory AppFailure.fromHttp({
    required int statusCode,
    required Object? body,
  }) {
    final payload = body is Map
        ? Map<String, dynamic>.from(body)
        : const <String, dynamic>{};
    final rawError = payload['error'];
    final error = rawError is Map
        ? Map<String, dynamic>.from(rawError)
        : const <String, dynamic>{};
    final code =
        payload['code'] as String? ?? error['code'] as String? ?? 'HTTP_ERROR';
    final message = payload['message'] as String? ??
        error['message'] as String? ??
        'Ocurrió un error inesperado.';
    final rawDetails = payload['details'] ?? error['details'];
    final details = rawDetails is Map
        ? Map<String, dynamic>.from(rawDetails)
        : const <String, dynamic>{};
    final rawMeta = payload['meta'];
    final meta = rawMeta is Map ? Map<String, dynamic>.from(rawMeta) : null;

    return AppFailure(
      code: code,
      message: message,
      kind: _kindFromStatus(statusCode),
      statusCode: statusCode,
      details: details,
      traceId: meta?['traceId'] as String?,
    );
  }

  static FailureKind _kindFromStatus(int statusCode) {
    if (statusCode == 401) return FailureKind.unauthorized;
    if (statusCode == 400 || statusCode == 422) return FailureKind.validation;
    if (statusCode == 404) return FailureKind.notFound;
    if (statusCode == 429) return FailureKind.rateLimited;
    if (statusCode >= 500) return FailureKind.unavailable;
    return FailureKind.unknown;
  }

  @override
  String toString() => '$code: $message';
}
