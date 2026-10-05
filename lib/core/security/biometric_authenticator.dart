import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

abstract interface class BiometricAuthenticator {
  bool get isAvailable;
  Future<void> initialize();
  Future<bool> authenticate();
}

class UnsupportedBiometricAuthenticator implements BiometricAuthenticator {
  const UnsupportedBiometricAuthenticator();

  @override
  bool get isAvailable => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> authenticate() async => false;
}

class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  LocalAuthBiometricAuthenticator({LocalAuthentication? localAuthentication})
      : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;
  bool _isAvailable = false;

  @override
  bool get isAvailable => _isAvailable;

  @override
  Future<void> initialize() async {
    try {
      final canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
      final availableBiometrics =
          await _localAuthentication.getAvailableBiometrics();
      _isAvailable = canCheckBiometrics && availableBiometrics.isNotEmpty;
    } on Object {
      _isAvailable = false;
    }
  }

  @override
  Future<bool> authenticate() async {
    if (!_isAvailable) return false;
    try {
      return await _localAuthentication.authenticate(
        localizedReason: 'Confirma tu identidad para continuar en BInova.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    } on Object {
      return false;
    }
  }
}
