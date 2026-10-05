import '../../../../core/storage/json_cache_store.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_data_source.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(
      {required TransactionRemoteDataSource remote,
      required JsonCacheStore cache})
      : _remote = remote,
        _cache = cache;

  final TransactionRemoteDataSource _remote;
  final JsonCacheStore _cache;

  @override
  Future<TransactionsPage> listTransactions(
    String accountId, {
    String? cursor,
    String? category,
    String? from,
    String? to,
  }) async {
    final isFirstPage =
        cursor == null && category == null && from == null && to == null;
    final key = 'binova.cache.transactions.v1.$accountId';
    try {
      final page = await _remote.fetchTransactions(
        accountId,
        cursor: cursor,
        category: category,
        from: from,
        to: to,
      );
      if (isFirstPage) {
        await _cache.write(
          key,
          <String, dynamic>{
            'items': page.items.map((item) => item.toMap()).toList(),
            'nextCursor': page.nextCursor,
          },
        );
      }
      return page;
    } on Object {
      if (!isFirstPage) rethrow;
      final cached = await _cache.read(key);
      if (cached == null || cached.payload is! Map) rethrow;
      final payload = Map<String, dynamic>.from(cached.payload as Map);
      final rawItems = payload['items'];
      if (rawItems is! List) rethrow;
      return TransactionsPage(
        items: rawItems
            .whereType<Map>()
            .map((item) => Transaction.fromMap(Map<String, dynamic>.from(item)))
            .toList(growable: false),
        nextCursor: payload['nextCursor'] as String?,
        fetchedAt: cached.fetchedAt,
        isStale: true,
      );
    }
  }

  @override
  Future<TransactionSnapshot> getTransaction(String id) async {
    final key = 'binova.cache.transaction.v1.$id';
    try {
      final transaction = await _remote.fetchTransaction(id);
      await _cache.write(key, transaction.toMap());
      return TransactionSnapshot(
        transaction: transaction,
        fetchedAt: DateTime.now(),
        isStale: false,
      );
    } on Object {
      final cached = await _cache.read(key);
      if (cached == null || cached.payload is! Map) rethrow;
      return TransactionSnapshot(
        transaction: Transaction.fromMap(
            Map<String, dynamic>.from(cached.payload as Map)),
        fetchedAt: cached.fetchedAt,
        isStale: true,
      );
    }
  }
}
