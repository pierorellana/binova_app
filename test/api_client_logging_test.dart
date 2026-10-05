import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:binova_app/core/config/app_config.dart';
import 'package:binova_app/core/errors/app_failure.dart';
import 'package:binova_app/core/network/api_client.dart';
import 'package:binova_app/core/observability/observability.dart';

void main() {
  test('logs safe response metadata without response data or secrets',
      () async {
    final logs = _RecordingObservability();
    final client = ApiClient(
      config: _config(),
      client: _QueueClient(
        http.Response(
          jsonEncode(<String, dynamic>{
            'data': <String, dynamic>{
              'ok': true,
              'balance': '1200.00',
              'accessToken': 'access-token',
            },
            'message': 'Operación exitosa.',
            'statusCode': 200,
            'meta': <String, dynamic>{'traceId': 'trace-response'},
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ),
      ),
      observability: logs,
    );

    await client.get('/dashboard');

    expect(logs.responses, hasLength(1));
    expect(logs.responses.single, containsPair('method', 'GET'));
    expect(logs.responses.single, containsPair('path', '/dashboard'));
    expect(logs.responses.single, containsPair('statusCode', 200));
    expect(
        logs.responses.single, containsPair('message', 'Operación exitosa.'));
    expect(logs.responses.single, containsPair('traceId', 'trace-response'));
    expect(logs.responses.single.containsKey('data'), isFalse);
    expect(logs.responses.single.containsKey('balance'), isFalse);
    expect(logs.responses.single.containsKey('accessToken'), isFalse);
  });

  test('parses the new error envelope into AppFailure', () {
    final failure = AppFailure.fromHttp(
      statusCode: 401,
      body: <String, dynamic>{
        'data': null,
        'message': 'La sesión expiró.',
        'statusCode': 401,
        'code': 'SESSION_EXPIRED',
        'details': <String, dynamic>{},
        'meta': <String, dynamic>{'traceId': 'trace-error'},
      },
    );

    expect(failure.code, 'SESSION_EXPIRED');
    expect(failure.message, 'La sesión expiró.');
    expect(failure.statusCode, 401);
    expect(failure.traceId, 'trace-error');
  });
}

AppConfig _config() => const AppConfig(
      apiBaseUrl: 'https://api.test/v1',
      environment: AppEnvironment.test,
      enableDemoTools: false,
    );

class _RecordingObservability implements Observability {
  final responses = <Map<String, Object?>>[];
  final errors = <Map<String, Object?>>[];

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
  }) {
    responses.add(<String, Object?>{
      'method': method,
      'path': path,
      'statusCode': statusCode,
      'latencyMs': latencyMs,
      'message': message,
      if (traceId != null) 'traceId': traceId,
      if (code != null) 'code': code,
    });
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
    errors.add(<String, Object?>{
      'method': method,
      'path': path,
      'statusCode': statusCode,
      'latencyMs': latencyMs,
      'code': code,
      if (traceId != null) 'traceId': traceId,
    });
  }
}

class _QueueClient extends http.BaseClient {
  _QueueClient(this.response);

  final http.Response response;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}
