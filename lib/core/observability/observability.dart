import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum AppEvent {
  screenView,
  loginSuccess,
  loginFailure,
  logout,
  offlineShown,
  retryTriggered,
  cacheFallbackUsed,
  operationStarted,
  operationResult,
}

abstract interface class Observability {
  void track(AppEvent event, {Map<String, Object?> parameters = const {}});

  void logApiResponse({
    required String method,
    required String path,
    required int statusCode,
    required int latencyMs,
    required String message,
    String? traceId,
    String? code,
  });

  void logApiError({
    required String method,
    required String path,
    required int? statusCode,
    required int latencyMs,
    required String code,
    String? traceId,
  });
}

class NoopObservability implements Observability {
  const NoopObservability();

  @override
  void track(AppEvent event, {Map<String, Object?> parameters = const {}}) {}

  @override
  void logApiResponse({
    required String method,
    required String path,
    required int statusCode,
    required int latencyMs,
    required String message,
    String? traceId,
    String? code,
  }) {}

  @override
  void logApiError({
    required String method,
    required String path,
    required int? statusCode,
    required int latencyMs,
    required String code,
    String? traceId,
  }) {}
}

class DebugObservability implements Observability {
  const DebugObservability({this.enabled = kDebugMode});

  final bool enabled;

  @override
  void track(AppEvent event, {Map<String, Object?> parameters = const {}}) {
    if (!enabled) return;
    developer.log(
      'event=${event.name} params=${_safe(parameters)}',
      name: 'BInova.Observability',
    );
  }

  @override
  void logApiResponse({
    required String method,
    required String path,
    required int statusCode,
    required int latencyMs,
    required String message,
    String? traceId,
    String? code,
  }) {
    if (!enabled) return;
    developer.log(
      _format(<String, Object?>{
        'event': 'api_response',
        'method': method,
        'path': path,
        'statusCode': statusCode,
        'latencyMs': latencyMs,
        'message': message,
        if (traceId != null) 'traceId': traceId,
        if (code != null) 'code': code,
      }),
      name: 'BInova.Api',
    );
  }

  @override
  void logApiError({
    required String method,
    required String path,
    required int? statusCode,
    required int latencyMs,
    required String code,
    String? traceId,
  }) {
    if (!enabled) return;
    developer.log(
      _format(<String, Object?>{
        'event': 'api_error',
        'method': method,
        'path': path,
        'statusCode': statusCode,
        'latencyMs': latencyMs,
        'code': code,
        if (traceId != null) 'traceId': traceId,
      }),
      name: 'BInova.Api',
      level: 900,
    );
  }

  Map<String, Object?> _safe(Map<String, Object?> parameters) {
    const allowed = <String>{'code', 'status', 'screen', 'operationType'};
    return Map<String, Object?>.fromEntries(
      parameters.entries.where((entry) => allowed.contains(entry.key)),
    );
  }

  String _format(Map<String, Object?> fields) =>
      fields.entries.map((entry) => '${entry.key}=${entry.value}').join(' ');
}
