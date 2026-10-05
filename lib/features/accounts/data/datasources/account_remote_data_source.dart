import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/account.dart';

abstract interface class AccountRemoteDataSource {
  Future<List<Account>> fetchAccounts();
  Future<Account> fetchAccount(String id);
}

class HttpAccountRemoteDataSource implements AccountRemoteDataSource {
  HttpAccountRemoteDataSource(this._client);

  final AuthenticatedApiClient _client;

  @override
  Future<List<Account>> fetchAccounts() async {
    final response = await _client.get('/accounts');
    final raw = response.data;
    if (raw is! List) throw const FormatException('Invalid accounts payload.');
    return raw
        .whereType<Map>()
        .map((item) => Account.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  @override
  Future<Account> fetchAccount(String id) async {
    final response = await _client.get('/accounts/$id');
    final raw = response.data;
    if (raw is! Map) throw const FormatException('Invalid account payload.');
    return Account.fromMap(Map<String, dynamic>.from(raw));
  }
}
