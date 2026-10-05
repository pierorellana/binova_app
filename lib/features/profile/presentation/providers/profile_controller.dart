import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/device.dart';
import '../../domain/entities/profile_preferences.dart';
import '../../domain/repositories/profile_repository.dart';

enum ProfileStatus { idle, loading, ready, failure, updating }

class ProfileController extends ChangeNotifier {
  ProfileController(this._repository);

  final ProfileRepository _repository;

  ProfileStatus status = ProfileStatus.idle;
  User? profile;
  ProfilePreferences? preferences;
  List<Device> devices = const <Device>[];
  String? errorMessage;

  bool get isReady =>
      profile != null && preferences != null && status != ProfileStatus.loading;

  Future<void> load() async {
    status = ProfileStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      profile = await _repository.getProfile();
      preferences = await _repository.getPreferences();
      devices = await _repository.listDevices();
      status = ProfileStatus.ready;
    } on AppFailure catch (error) {
      status = ProfileStatus.failure;
      errorMessage = error.message;
    } on Object {
      status = ProfileStatus.failure;
      errorMessage = 'No pudimos cargar tu perfil.';
    }
    notifyListeners();
  }

  Future<void> updatePreference(String key, bool value) async {
    final current = preferences;
    if (current == null || status == ProfileStatus.updating) return;
    final previous = current;
    preferences = current.copyWith(
      hideBalance: key == 'hideBalance' ? value : null,
      reduceMotion: key == 'reduceMotion' ? value : null,
      notificationsEnabled: key == 'notificationsEnabled' ? value : null,
    );
    status = ProfileStatus.updating;
    errorMessage = null;
    notifyListeners();
    try {
      preferences = await _repository.updatePreferences(<String, dynamic>{
        key: value,
      });
      status = ProfileStatus.ready;
    } on AppFailure catch (error) {
      preferences = previous;
      status = ProfileStatus.ready;
      errorMessage = error.message;
    } on Object {
      preferences = previous;
      status = ProfileStatus.ready;
      errorMessage = 'No pudimos guardar la preferencia.';
    }
    notifyListeners();
  }

  Future<void> revokeDevice(String id) async {
    await _repository.revokeDevice(id);
    devices =
        devices.where((device) => device.id != id).toList(growable: false);
    notifyListeners();
  }
}
