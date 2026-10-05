import '../../../../core/network/authenticated_api_client.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/device.dart';
import '../../domain/entities/profile_preferences.dart';

abstract interface class ProfileRemoteDataSource {
  Future<User> fetchProfile();
  Future<ProfilePreferences> fetchPreferences();
  Future<ProfilePreferences> updatePreferences(Map<String, dynamic> changes);
  Future<List<Device>> fetchDevices();
  Future<Device> registerDevice({
    required String platform,
    required String pushToken,
    String? deviceLabel,
  });
  Future<void> revokeDevice(String id);
}

class HttpProfileRemoteDataSource implements ProfileRemoteDataSource {
  HttpProfileRemoteDataSource(this._client);

  final AuthenticatedApiClient _client;

  @override
  Future<User> fetchProfile() async {
    final response = await _client.get('/profile');
    if (response.data is! Map) {
      throw const FormatException('Invalid profile payload.');
    }
    return User.fromMap(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<ProfilePreferences> fetchPreferences() async {
    final response = await _client.get('/profile/preferences');
    if (response.data is! Map) {
      throw const FormatException('Invalid preferences payload.');
    }
    return ProfilePreferences.fromMap(
        Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<ProfilePreferences> updatePreferences(
      Map<String, dynamic> changes) async {
    final response = await _client.patch(
      '/profile/preferences',
      body: changes,
    );
    if (response.data is! Map) {
      throw const FormatException('Invalid preferences payload.');
    }
    return ProfilePreferences.fromMap(
        Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<List<Device>> fetchDevices() async {
    final response = await _client.get('/devices');
    if (response.data is! List) {
      throw const FormatException('Invalid devices payload.');
    }
    return (response.data as List)
        .whereType<Map>()
        .map((item) => Device.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  @override
  Future<Device> registerDevice({
    required String platform,
    required String pushToken,
    String? deviceLabel,
  }) async {
    final response = await _client.post(
      '/devices',
      body: <String, dynamic>{
        'platform': platform,
        'pushToken': pushToken,
        if (deviceLabel != null) 'deviceLabel': deviceLabel,
      },
    );
    if (response.data is! Map) {
      throw const FormatException('Invalid device payload.');
    }
    return Device.fromMap(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<void> revokeDevice(String id) async {
    await _client.delete('/devices/$id');
  }
}
