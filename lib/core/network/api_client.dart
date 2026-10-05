import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../errors/app_failure.dart';
import '../observability/observability.dart';
import 'demo_network_mode.dart';

class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.data,
    required this.message,
    required this.meta,
    this.code,
    this.details = const <String, dynamic>{},
  });

  final int statusCode;
  final dynamic data;
  final String message;
  final Map<String, dynamic> meta;
  final String? code;
  final Map<String, dynamic> details;
}

class ApiClient {
  ApiClient({
    required AppConfig config,
    http.Client? client,
    DemoNetworkModeController? demoMode,
    Observability? observability,
  })  : _config = config,
        _client = client ?? http.Client(),
        _demoMode = demoMode ?? DemoNetworkModeController(),
        _observability = observability ?? const NoopObservability();

  final AppConfig _config;
  final http.Client _client;
  final DemoNetworkModeController _demoMode;
  final Observability _observability;

  Future<ApiResponse> get(
    String path, {
    String? accessToken,
    Map<String, String?> queryParameters = const <String, String?>{},
  }) {
    return request(
      'GET',
      path,
      accessToken: accessToken,
      queryParameters: queryParameters,
    );
  }

  Future<ApiResponse> post(
    String path, {
    String? accessToken,
    Map<String, dynamic>? body,
    String? idempotencyKey,
    Map<String, String?> queryParameters = const <String, String?>{},
  }) {
    return request(
      'POST',
      path,
      accessToken: accessToken,
      body: body,
      idempotencyKey: idempotencyKey,
      queryParameters: queryParameters,
    );
  }

  Future<ApiResponse> patch(
    String path, {
    String? accessToken,
    Map<String, dynamic>? body,
  }) {
    return request(
      'PATCH',
      path,
      accessToken: accessToken,
      body: body,
    );
  }

  Future<ApiResponse> delete(
    String path, {
    String? accessToken,
  }) {
    return request(
      'DELETE',
      path,
      accessToken: accessToken,
    );
  }

  Future<ApiResponse> request(
    String method,
    String path, {
    String? accessToken,
    Map<String, dynamic>? body,
    String? idempotencyKey,
    Map<String, String?> queryParameters = const <String, String?>{},
  }) async {
    final stopwatch = Stopwatch()..start();
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final parsedUri = Uri.parse('${_config.apiBaseUrl}/$normalizedPath');
    final uriQuery = <String, String>{...parsedUri.queryParameters};
    queryParameters.forEach((key, value) {
      if (value != null) uriQuery[key] = value;
    });
    final uri = parsedUri.replace(queryParameters: uriQuery);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Correlation-Id': _correlationId(),
    };
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    if (idempotencyKey != null) {
      headers['Idempotency-Key'] = idempotencyKey;
    }

    try {
      await _simulateDemoMode();
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed =
          await _client.send(request).timeout(_config.requestTimeout);
      final response = await http.Response.fromStream(streamed);
      final payload = _decode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppFailure.fromHttp(
          statusCode: response.statusCode,
          body: payload,
        );
      }
      final map = payload is Map
          ? Map<String, dynamic>.from(payload)
          : <String, dynamic>{};
      final rawMeta = map['meta'];
      final meta = rawMeta is Map
          ? Map<String, dynamic>.from(rawMeta)
          : const <String, dynamic>{};
      final apiResponse = ApiResponse(
        statusCode: response.statusCode,
        data: map['data'],
        message: map['message'] as String? ?? 'Operación exitosa.',
        meta: meta,
        code: map['code'] as String?,
        details: map['details'] is Map
            ? Map<String, dynamic>.from(map['details'] as Map)
            : const <String, dynamic>{},
      );
      _observability.logApiResponse(
        method: method,
        path: '/$normalizedPath',
        statusCode: apiResponse.statusCode,
        latencyMs: stopwatch.elapsedMilliseconds,
        message: apiResponse.message,
        traceId: apiResponse.meta['traceId'] as String?,
        code: apiResponse.code,
      );
      return apiResponse;
    } on AppFailure catch (error) {
      _observability.logApiError(
        method: method,
        path: '/$normalizedPath',
        statusCode: error.statusCode,
        latencyMs: stopwatch.elapsedMilliseconds,
        code: error.code,
        traceId: error.traceId,
      );
      rethrow;
    } on TimeoutException catch (error) {
      final failure = AppFailure.network(error);
      _observability.logApiError(
        method: method,
        path: '/$normalizedPath',
        statusCode: failure.statusCode,
        latencyMs: stopwatch.elapsedMilliseconds,
        code: failure.code,
        traceId: failure.traceId,
      );
      throw failure;
    } on http.ClientException catch (error) {
      final failure = AppFailure.network(error);
      _observability.logApiError(
        method: method,
        path: '/$normalizedPath',
        statusCode: failure.statusCode,
        latencyMs: stopwatch.elapsedMilliseconds,
        code: failure.code,
        traceId: failure.traceId,
      );
      throw failure;
    }
  }

  dynamic _decode(String body) {
    if (body.trim().isEmpty) return const <String, dynamic>{};
    try {
      return jsonDecode(body);
    } on FormatException catch (error) {
      throw AppFailure.network(error);
    }
  }

  String _correlationId() =>
      'mobile-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Future<void> _simulateDemoMode() async {
    switch (_demoMode.value) {
      case DemoNetworkMode.normal:
        return;
      case DemoNetworkMode.slow:
        await Future<void>.delayed(const Duration(seconds: 3));
      case DemoNetworkMode.offline:
        throw AppFailure.network(StateError('demo_offline'));
      case DemoNetworkMode.serverError:
        throw AppFailure.fromHttp(
          statusCode: 500,
          body: const <String, dynamic>{
            'data': null,
            'message': 'Error simulado por Developer Tools.',
            'statusCode': 500,
            'code': 'DEMO_SERVER_ERROR',
            'details': <String, dynamic>{},
            'meta': <String, dynamic>{},
          },
        );
      case DemoNetworkMode.timeout:
        throw TimeoutException('demo_timeout');
    }
  }
}
