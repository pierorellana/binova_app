import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/device.dart';
import '../../domain/entities/profile_preferences.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<User> getProfile() => _remote.fetchProfile();

  @override
  Future<ProfilePreferences> getPreferences() => _remote.fetchPreferences();

  @override
  Future<ProfilePreferences> updatePreferences(Map<String, dynamic> changes) =>
      _remote.updatePreferences(changes);

  @override
  Future<List<Device>> listDevices() => _remote.fetchDevices();

  @override
  Future<Device> registerDevice({
    required String platform,
    required String pushToken,
    String? deviceLabel,
  }) =>
      _remote.registerDevice(
        platform: platform,
        pushToken: pushToken,
        deviceLabel: deviceLabel,
      );

  @override
  Future<void> revokeDevice(String id) => _remote.revokeDevice(id);
}
