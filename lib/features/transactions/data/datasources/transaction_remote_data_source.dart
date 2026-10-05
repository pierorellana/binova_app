import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

abstract interface class TransactionRemoteDataSource {
  Future<TransactionsPage> fetchTransactions(
    String accountId, {
    String? cursor,
    String? category,
    String? from,
    String? to,
  });

  Future<Transaction> fetchTransaction(String id);
}

class HttpTransactionRemoteDataSource implements TransactionRemoteDataSource {
  HttpTransactionRemoteDataSource(this._client);

  final AuthenticatedApiClient _client;

  @override
  Future<TransactionsPage> fetchTransactions(
    String accountId, {
    String? cursor,
    String? category,
    String? from,
    String? to,
  }) async {
    final response = await _client.get(
      '/accounts/$accountId/transactions',
      queryParameters: <String, String?>{
        'cursor': cursor,
        'category': category,
        'from': from,
        'to': to,
      },
    );
    final raw = response.data;
    if (raw is! List) {
      throw const FormatException('Invalid transactions payload.');
    }
    final items = raw
        .whereType<Map>()
        .map((item) => Transaction.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    return TransactionsPage(
      items: items,
      nextCursor: response.meta['nextCursor'] as String?,
      fetchedAt: DateTime.now(),
      isStale: false,
    );
  }

  @override
  Future<Transaction> fetchTransaction(String id) async {
    final response = await _client.get('/transactions/$id');
    final raw = response.data;
    if (raw is! Map) {
      throw const FormatException('Invalid transaction payload.');
    }
    return Transaction.fromMap(Map<String, dynamic>.from(raw));
  }
}
