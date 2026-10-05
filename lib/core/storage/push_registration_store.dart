import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PushRegistrationStore {
  Future<String?> readDeviceId();
  Future<void> writeDeviceId(String deviceId);
  Future<void> clearDeviceId();
}

class SharedPreferencesPushRegistrationStore implements PushRegistrationStore {
  SharedPreferencesPushRegistrationStore(this._preferences);

  static const _key = 'binova.push.registration.v1';
  final SharedPreferences _preferences;

  @override
  Future<String?> readDeviceId() async {
    final value = _preferences.getString(_key);
    return value == null || value.isEmpty ? null : value;
  }

  @override
  Future<void> writeDeviceId(String deviceId) =>
      _preferences.setString(_key, deviceId);

  @override
  Future<void> clearDeviceId() => _preferences.remove(_key);
}
