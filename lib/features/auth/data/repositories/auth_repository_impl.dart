import '../../../../core/errors/app_failure.dart';
import '../../../../core/security/biometric_preference_store.dart';
import '../../../../core/storage/onboarding_store.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required OnboardingStore onboarding,
    required BiometricPreferenceStore biometricPreference,
  })  : _remote = remote,
        _local = local,
        _onboarding = onboarding,
        _biometricPreference = biometricPreference;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final OnboardingStore _onboarding;
  final BiometricPreferenceStore _biometricPreference;

  @override
  Future<InitialDestination> resolveInitialDestination() async {
    if (!await _onboarding.isCompleted()) {
      return InitialDestination.onboarding;
    }

    final session = await _local.readSession();
    if (session == null || !session.isRefreshTokenValid) {
      await _local.clearSession();
      return InitialDestination.login;
    }
    return await _biometricPreference.isEnabled()
        ? InitialDestination.biometric
        : InitialDestination.login;
  }

  @override
  Future<Session> login(
      {required String username, required String password}) async {
    final session = await _remote.login(username: username, password: password);
    await _local.saveSession(session);
    return session;
  }

  @override
  Future<Session> unlockSession() async {
    final stored = await _local.readSession();
    if (stored == null || !stored.isRefreshTokenValid) {
      await _local.clearSession();
      throw const AppFailure(
        code: 'SESSION_EXPIRED',
        message: 'Tu sesión expiró. Ingresa nuevamente.',
        kind: FailureKind.unauthorized,
      );
    }
    if (stored.isAccessTokenValid) return stored;

    try {
      final refreshed =
          await _remote.refresh(refreshToken: stored.refreshToken);
      await _local.saveSession(refreshed);
      return refreshed;
    } on AppFailure catch (error) {
      if (error.kind == FailureKind.unauthorized ||
          error.code == 'REFRESH_REVOKED' ||
          error.code == 'SESSION_EXPIRED') {
        await _local.clearSession();
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      final session = await _local.readSession();
      if (session != null && session.accessToken.isNotEmpty) {
        await _remote.logout(accessToken: session.accessToken);
      }
    } finally {
      // Local sign-out is mandatory even when the API is unavailable.
      await _local.clearSession();
    }
  }

  @override
  Future<bool> hasStoredSession() async {
    final session = await _local.readSession();
    if (session == null) return false;
    if (!session.isRefreshTokenValid) {
      await _local.clearSession();
      return false;
    }
    return true;
  }
}
