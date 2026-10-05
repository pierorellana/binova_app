import '../errors/app_failure.dart';
import '../security/secure_session_store.dart';
import '../../features/auth/domain/entities/session.dart';
import 'api_client.dart';

class AuthenticatedApiClient {
  AuthenticatedApiClient({
    required ApiClient client,
    required SecureSessionStore sessionStore,
    Future<Session> Function(String refreshToken)? refreshSession,
  })  : _client = client,
        _sessionStore = sessionStore,
        _refreshSession = refreshSession;

  final ApiClient _client;
  final SecureSessionStore _sessionStore;
  final Future<Session> Function(String refreshToken)? _refreshSession;
  Future<Session>? _refreshInFlight;

  Future<ApiResponse> get(
    String path, {
    Map<String, String?> queryParameters = const <String, String?>{},
  }) async {
    return _withAuthenticatedSession(
      (session) => _client.get(
        path,
        accessToken: session.accessToken,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async {
    return _withAuthenticatedSession(
      (session) => _client.post(
        path,
        accessToken: session.accessToken,
        body: body,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  Future<ApiResponse> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _withAuthenticatedSession(
      (session) => _client.patch(
        path,
        accessToken: session.accessToken,
        body: body,
      ),
    );
  }

  Future<ApiResponse> delete(String path) async {
    return _withAuthenticatedSession(
      (session) => _client.delete(
        path,
        accessToken: session.accessToken,
      ),
    );
  }

  Future<ApiResponse> _withAuthenticatedSession(
    Future<ApiResponse> Function(Session session) request,
  ) async {
    final initial = await _sessionStore.read();
    if (initial == null) {
      throw StateError('An authenticated request requires a local session.');
    }

    final session =
        initial.isAccessTokenValid ? initial : await _refreshOrThrow(initial);
    try {
      return await request(session);
    } on AppFailure catch (error) {
      if (error.kind != FailureKind.unauthorized || _refreshSession == null) {
        rethrow;
      }
      final refreshed = await _refreshOrThrow(session);
      try {
        return await request(refreshed);
      } on AppFailure catch (retryError) {
        if (retryError.kind == FailureKind.unauthorized) {
          await _sessionStore.clear();
        }
        rethrow;
      }
    }
  }

  Future<Session> _refreshOrThrow(Session current) async {
    final refresh = _refreshSession;
    if (refresh == null) {
      await _sessionStore.clear();
      throw const AppFailure(
        code: 'SESSION_EXPIRED',
        message: 'Tu sesión expiró. Ingresa nuevamente.',
        kind: FailureKind.unauthorized,
      );
    }

    try {
      final refreshed = await _refresh(refreshToken: current.refreshToken);
      await _sessionStore.write(refreshed);
      return refreshed;
    } on AppFailure catch (error) {
      if (error.kind == FailureKind.unauthorized ||
          error.code == 'REFRESH_REVOKED' ||
          error.code == 'SESSION_EXPIRED') {
        await _sessionStore.clear();
      }
      rethrow;
    }
  }

  Future<Session> _refresh({required String refreshToken}) {
    final pending = _refreshInFlight;
    if (pending != null) return pending;
    final refresh = _refreshSession!;
    final request = refresh(refreshToken);
    _refreshInFlight = request;
    return request.whenComplete(() {
      _refreshInFlight = null;
    });
  }
}
