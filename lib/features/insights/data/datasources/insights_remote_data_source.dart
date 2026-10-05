import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/insights.dart';

abstract interface class InsightsRemoteDataSource {
  Future<Insights> fetchMonthly();
}

class HttpInsightsRemoteDataSource implements InsightsRemoteDataSource {
  HttpInsightsRemoteDataSource(this._client);

  final AuthenticatedApiClient _client;

  @override
  Future<Insights> fetchMonthly() async {
    final response = await _client.get(
      '/insights/monthly',
      queryParameters: const <String, String?>{'period': 'month'},
    );
    if (response.data is! Map) {
      throw const FormatException('Invalid insights payload.');
    }
    return Insights.fromMap(Map<String, dynamic>.from(response.data as Map));
  }
}
