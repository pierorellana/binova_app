import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OnboardingStore {
  Future<bool> isCompleted();
  Future<void> markCompleted();
}

class SharedPreferencesOnboardingStore implements OnboardingStore {
  SharedPreferencesOnboardingStore(this._preferences);

  static const _completedKey = 'binova.onboarding.completed';
  final SharedPreferences _preferences;

  @override
  Future<bool> isCompleted() async =>
      _preferences.getBool(_completedKey) ?? false;

  @override
  Future<void> markCompleted() async {
    await _preferences.setBool(_completedKey, true);
  }
}
