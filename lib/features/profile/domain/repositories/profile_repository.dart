import '../../../auth/domain/entities/user.dart';
import '../entities/device.dart';
import '../entities/profile_preferences.dart';

abstract interface class ProfileRepository {
  Future<User> getProfile();
  Future<ProfilePreferences> getPreferences();
  Future<ProfilePreferences> updatePreferences(Map<String, dynamic> changes);
  Future<List<Device>> listDevices();
  Future<Device> registerDevice({
    required String platform,
    required String pushToken,
    String? deviceLabel,
  });
  Future<void> revokeDevice(String id);
}
