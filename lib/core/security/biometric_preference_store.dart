import 'package:shared_preferences/shared_preferences.dart';

abstract interface class BiometricPreferenceStore {
  Future<bool> isEnabled();
  Future<void> setEnabled(bool enabled);
}

class SharedPreferencesBiometricPreferenceStore
    implements BiometricPreferenceStore {
  SharedPreferencesBiometricPreferenceStore(this._preferences);

  static const _key = 'binova.biometric.enabled.v1';
  final SharedPreferences _preferences;

  @override
  Future<bool> isEnabled() async => _preferences.getBool(_key) ?? true;

  @override
  Future<void> setEnabled(bool enabled) => _preferences.setBool(_key, enabled);
}
