import 'package:flutter_test/flutter_test.dart';

import 'package:binova_app/core/security/biometric_authenticator.dart';
import 'package:binova_app/core/notifications/push_notification_service.dart';
import 'package:binova_app/features/auth/domain/entities/session.dart';
import 'package:binova_app/features/auth/domain/entities/user.dart';
import 'package:binova_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:binova_app/features/auth/presentation/providers/auth_controller.dart';

void main() {
  test('unlocks a valid local session after biometric acceptance', () async {
    final session = _session();
    final repository = _FakeAuthRepository(session);
    final biometric = _FakeBiometric(isAvailable: true, accepted: true);
    final controller = AuthController(
      repository: repository,
      biometric: biometric,
    );

    final unlocked = await controller.unlockWithBiometry();

    expect(unlocked, isTrue);
    expect(controller.status, AuthStatus.authenticated);
    expect(repository.unlockCalls, 1);
  });

  test('does not unlock when biometric hardware is unavailable', () async {
    final repository = _FakeAuthRepository(_session());
    final controller = AuthController(
      repository: repository,
      biometric: _FakeBiometric(isAvailable: false, accepted: false),
    );

    final unlocked = await controller.unlockWithBiometry();

    expect(unlocked, isFalse);
    expect(controller.status, AuthStatus.failure);
    expect(repository.unlockCalls, 0);
  });

  test('activates push after login and deactivates it on logout', () async {
    final push = _FakePushRegistrationCoordinator();
    final controller = AuthController(
      repository: _FakeAuthRepository(_session()),
      biometric: _FakeBiometric(isAvailable: true, accepted: true),
      pushNotifications: push,
    );

    await controller.login(username: 'demo', password: 'password');
    await controller.logout();

    expect(push.activateCalls, 1);
    expect(push.deactivateCalls, 1);
  });
}

Session _session({
  Duration accessLifetime = const Duration(minutes: 15),
}) {
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

class _FakeBiometric implements BiometricAuthenticator {
  _FakeBiometric({required this.isAvailable, required this.accepted});

  @override
  final bool isAvailable;

  final bool accepted;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> authenticate() async => accepted;
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.session);

  final Session session;
  int unlockCalls = 0;

  @override
  Future<bool> hasStoredSession() async => true;

  @override
  Future<Session> login(
          {required String username, required String password}) async =>
      session;

  @override
  Future<void> logout() async {}

  @override
  Future<InitialDestination> resolveInitialDestination() async =>
      InitialDestination.biometric;

  @override
  Future<Session> unlockSession() async {
    unlockCalls++;
    return session;
  }
}

class _FakePushRegistrationCoordinator implements PushRegistrationCoordinator {
  int activateCalls = 0;
  int deactivateCalls = 0;

  @override
  Future<void> activate() async {
    activateCalls++;
  }

  @override
  Future<void> deactivate() async {
    deactivateCalls++;
  }
}
