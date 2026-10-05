import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/exchange_rate.dart';

abstract interface class ExchangeRateRemoteDataSource {
  Future<ExchangeRate> fetch({required String base, required String quote});
}

class HttpExchangeRateRemoteDataSource implements ExchangeRateRemoteDataSource {
  HttpExchangeRateRemoteDataSource(this._client);

  final AuthenticatedApiClient _client;

  @override
  Future<ExchangeRate> fetch(
      {required String base, required String quote}) async {
    final response = await _client.get(
      '/exchange-rates',
      queryParameters: <String, String?>{'base': base, 'quote': quote},
    );
    if (response.data is! Map) {
      throw const FormatException('Invalid exchange rate payload.');
    }
    return ExchangeRate.fromMap(
        Map<String, dynamic>.from(response.data as Map));
  }
}
