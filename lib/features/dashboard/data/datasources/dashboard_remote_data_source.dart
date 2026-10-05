import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/dashboard_config.dart';

abstract interface class DashboardRemoteDataSource {
  Future<DashboardConfig> fetch();
}

class HttpDashboardRemoteDataSource implements DashboardRemoteDataSource {
  HttpDashboardRemoteDataSource(this._client);

  final AuthenticatedApiClient _client;

  @override
  Future<DashboardConfig> fetch() async {
    final response = await _client.get('/dashboard');
    return DashboardConfig.fromMap(
        Map<String, dynamic>.from(response.data as Map));
  }
}
