import '../entities/session.dart';

enum InitialDestination { onboarding, login, biometric }

abstract interface class AuthRepository {
  Future<InitialDestination> resolveInitialDestination();
  Future<Session> login({required String username, required String password});
  Future<Session> unlockSession();
  Future<void> logout();
  Future<bool> hasStoredSession();
}
