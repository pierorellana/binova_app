import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:binova_app/core/config/app_config.dart';
import 'package:binova_app/core/errors/app_failure.dart';
import 'package:binova_app/core/network/api_client.dart';
import 'package:binova_app/core/network/demo_network_mode.dart';

void main() {
  test('offline mode fails before sending a request', () async {
    final transport = _RecordingClient();
    final mode = DemoNetworkModeController()..value = DemoNetworkMode.offline;
    final client = ApiClient(
      config: _config(),
      client: transport,
      demoMode: mode,
    );

    await expectLater(
      client.get('/dashboard'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          'NETWORK_UNAVAILABLE',
        ),
      ),
    );
    expect(transport.requestCount, 0);
  });

  test('server error mode exposes a resolvable demo error code', () async {
    final mode = DemoNetworkModeController()
      ..value = DemoNetworkMode.serverError;
    final client = ApiClient(config: _config(), demoMode: mode);

    await expectLater(
      client.get('/dashboard'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          'DEMO_SERVER_ERROR',
        ),
      ),
    );
  });
}

AppConfig _config() => const AppConfig(
      apiBaseUrl: 'https://api.test/v1',
      environment: AppEnvironment.test,
      enableDemoTools: false,
    );

class _RecordingClient extends http.BaseClient {
  int requestCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestCount++;
    return http.StreamedResponse(
      Stream<List<int>>.value(
        utf8.encode(
          '{"data":{},"message":"Operación exitosa.","statusCode":200,"meta":{}}',
        ),
      ),
      200,
      request: request,
    );
  }
}
