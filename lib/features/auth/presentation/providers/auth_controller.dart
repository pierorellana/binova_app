import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/observability/observability.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../../core/security/biometric_authenticator.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus {
  idle,
  loading,
  biometricScanning,
  authenticated,
  failure,
}

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repository,
    required BiometricAuthenticator biometric,
    Observability observability = const NoopObservability(),
    PushRegistrationCoordinator pushNotifications =
        const NoopPushRegistrationCoordinator(),
  })  : _repository = repository,
        _biometric = biometric,
        _observability = observability,
        _pushNotifications = pushNotifications;

  final AuthRepository _repository;
  final BiometricAuthenticator _biometric;
  final Observability _observability;
  final PushRegistrationCoordinator _pushNotifications;

  AuthStatus status = AuthStatus.idle;
  Session? session;
  String? errorMessage;

  bool get biometricAvailable => _biometric.isAvailable;
  bool get isLoading =>
      status == AuthStatus.loading || status == AuthStatus.biometricScanning;

  Future<void> login(
      {required String username, required String password}) async {
    if (isLoading) return;
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      session = await _repository.login(username: username, password: password);
      await _activatePush();
      status = AuthStatus.authenticated;
      _observability.track(AppEvent.loginSuccess);
    } on AppFailure catch (error) {
      status = AuthStatus.failure;
      errorMessage = error.message;
      _observability.track(
        AppEvent.loginFailure,
        parameters: <String, Object?>{'code': error.code},
      );
    } on Object {
      status = AuthStatus.failure;
      errorMessage = 'No pudimos iniciar sesión. Inténtalo de nuevo.';
      _observability.track(AppEvent.loginFailure);
    }
    notifyListeners();
  }

  Future<bool> unlockWithBiometry() async {
    if (isLoading) return false;
    if (!_biometric.isAvailable) {
      status = AuthStatus.failure;
      errorMessage = 'Face ID no está disponible en este dispositivo.';
      notifyListeners();
      return false;
    }
    status = AuthStatus.biometricScanning;
    errorMessage = null;
    notifyListeners();
    try {
      final accepted = await _biometric.authenticate();
      if (!accepted) {
        status = AuthStatus.failure;
        errorMessage = 'No pudimos validar tu identidad.';
        notifyListeners();
        return false;
      }
      session = await _repository.unlockSession();
      await _activatePush();
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AppFailure catch (error) {
      status = AuthStatus.failure;
      errorMessage = error.message;
    } on Object {
      status = AuthStatus.failure;
      errorMessage = 'No pudimos recuperar tu sesión.';
    }
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    try {
      await _deactivatePush();
      await _repository.logout();
    } on Object {
      _observability.track(
        AppEvent.pushRegistrationFailure,
        parameters: const <String, Object?>{'status': 'logout_failed'},
      );
    } finally {
      session = null;
      status = AuthStatus.idle;
      errorMessage = null;
      _observability.track(AppEvent.logout);
      notifyListeners();
    }
  }

  Future<void> _activatePush() async {
    try {
      await _pushNotifications.activate();
    } on Object {
      _observability.track(AppEvent.pushRegistrationFailure);
    }
  }

  Future<void> _deactivatePush() async {
    try {
      await _pushNotifications.deactivate();
    } on Object {
      _observability.track(AppEvent.pushRegistrationFailure);
    }
  }
}
