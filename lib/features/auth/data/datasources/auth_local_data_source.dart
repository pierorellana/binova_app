import '../../../../core/security/secure_session_store.dart';
import '../../domain/entities/session.dart';

abstract interface class AuthLocalDataSource {
  Future<Session?> readSession();
  Future<void> saveSession(Session session);
  Future<void> clearSession();
}

class SecureAuthLocalDataSource implements AuthLocalDataSource {
  SecureAuthLocalDataSource(this._store);

  final SecureSessionStore _store;

  @override
  Future<Session?> readSession() => _store.read();

  @override
  Future<void> saveSession(Session session) => _store.write(session);

  @override
  Future<void> clearSession() => _store.clear();
}
