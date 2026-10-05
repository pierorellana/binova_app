import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:binova_app/core/config/app_config.dart';
import 'package:binova_app/core/errors/app_failure.dart';
import 'package:binova_app/core/network/api_client.dart';
import 'package:binova_app/core/network/authenticated_api_client.dart';
import 'package:binova_app/core/security/secure_session_store.dart';
import 'package:binova_app/features/auth/domain/entities/session.dart';
import 'package:binova_app/features/auth/domain/entities/user.dart';

void main() {
  test('refreshes an expired access token before the request', () async {
    final oldSession = _session(accessLifetime: const Duration(seconds: -1));
    final refreshed = _session();
    final store = _FakeSessionStore(oldSession);
    final client = _QueueClient(<http.Response>[
      _successResponse(),
    ]);
    var refreshCalls = 0;
    final authenticated = AuthenticatedApiClient(
      client: ApiClient(config: _config(), client: client),
      sessionStore: store,
      refreshSession: (refreshToken) async {
        refreshCalls++;
        expect(refreshToken, oldSession.refreshToken);
        return refreshed;
      },
    );

    await authenticated.get('/dashboard');

    expect(refreshCalls, 1);
    expect(store.value, refreshed);
    expect(client.authorizationHeaders, ['Bearer ${refreshed.accessToken}']);
  });

  test('retries one 401 after refresh and clears on a second 401', () async {
    final initial = _session();
    final refreshed = _session().copyWithToken('new-access-token');
    final store = _FakeSessionStore(initial);
    final client = _QueueClient(<http.Response>[
      _errorResponse(401),
      _errorResponse(401),
    ]);
    final authenticated = AuthenticatedApiClient(
      client: ApiClient(config: _config(), client: client),
      sessionStore: store,
      refreshSession: (_) async => refreshed,
    );

    await expectLater(
      authenticated.get('/accounts'),
      throwsA(isA<AppFailure>()),
    );

    expect(client.authorizationHeaders, [
      'Bearer ${initial.accessToken}',
      'Bearer ${refreshed.accessToken}',
    ]);
    expect(store.value, isNull);
  });
}

AppConfig _config() => const AppConfig(
      apiBaseUrl: 'https://api.test/v1',
      environment: AppEnvironment.test,
      enableDemoTools: true,
    );

http.Response _successResponse() => http.Response(
      jsonEncode(<String, dynamic>{
        'data': <String, dynamic>{'ok': true},
        'meta': <String, dynamic>{},
      }),
      200,
      headers: <String, String>{'content-type': 'application/json'},
    );

http.Response _errorResponse(int statusCode) => http.Response(
      jsonEncode(<String, dynamic>{
        'error': <String, dynamic>{
          'code': 'SESSION_EXPIRED',
          'message': 'expired',
          'details': <String, dynamic>{},
        },
        'traceId': 'trace-test',
      }),
      statusCode,
      headers: <String, String>{'content-type': 'application/json'},
    );

Session _session({Duration accessLifetime = const Duration(minutes: 15)}) {
  final now = DateTime.now().toUtc();
  return Session(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: now.add(accessLifetime),
    refreshTokenExpiresAt: now.add(const Duration(days: 7)),
    user: User(
      id: 'user-1',
      email: 'demo@binova.test',
      displayName: 'Demo',
      segment: 'mass',
    ),
  );
}

extension on Session {
  Session copyWithToken(String token) => Session(
        accessToken: token,
        refreshToken: refreshToken,
        accessTokenExpiresAt: accessTokenExpiresAt,
        refreshTokenExpiresAt: refreshTokenExpiresAt,
        user: user,
      );
}

class _FakeSessionStore implements SecureSessionStore {
  _FakeSessionStore(this.value);

  Session? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<Session?> read() async => value;

  @override
  Future<void> write(Session session) async => value = session;
}

class _QueueClient extends http.BaseClient {
  _QueueClient(this.responses);

  final List<http.Response> responses;
  final authorizationHeaders = <String>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    authorizationHeaders.add(request.headers['Authorization'] ?? '');
    final response = responses.removeAt(0);
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}
