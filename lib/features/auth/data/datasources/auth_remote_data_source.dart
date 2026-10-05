import '../../../../core/network/api_client.dart';
import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/session.dart';

abstract interface class AuthRemoteDataSource {
  Future<Session> login({required String username, required String password});
  Future<Session> refresh({required String refreshToken});
  Future<void> logout({required String accessToken});
}

class HttpAuthRemoteDataSource implements AuthRemoteDataSource {
  HttpAuthRemoteDataSource(this._client);

  final ApiClient _client;

  @override
  Future<Session> login(
      {required String username, required String password}) async {
    final response = await _client.post(
      '/auth/login',
      body: <String, dynamic>{'username': username, 'password': password},
    );
    return _sessionFromResponse(response);
  }

  @override
  Future<Session> refresh({required String refreshToken}) async {
    final response = await _client.post(
      '/auth/refresh',
      body: <String, dynamic>{'refreshToken': refreshToken},
    );
    return _sessionFromResponse(response);
  }

  @override
  Future<void> logout({required String accessToken}) async {
    await _client.post('/auth/logout', accessToken: accessToken);
  }

  Session _sessionFromResponse(ApiResponse response) {
    final data = response.data;
    if (data is! Map) {
      throw const AppFailure(
        code: 'INVALID_SESSION_RESPONSE',
        message: 'El servidor devolvió una sesión inválida.',
        kind: FailureKind.unknown,
      );
    }

    try {
      return Session.fromMap(Map<String, dynamic>.from(data));
    } on FormatException {
      throw const AppFailure(
        code: 'INVALID_SESSION_RESPONSE',
        message: 'El servidor devolvió una sesión inválida.',
        kind: FailureKind.unknown,
      );
    } on ArgumentError {
      throw const AppFailure(
        code: 'INVALID_SESSION_RESPONSE',
        message: 'El servidor devolvió una sesión inválida.',
        kind: FailureKind.unknown,
      );
    }
  }
}
