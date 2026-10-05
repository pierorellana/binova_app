import '../../../../core/storage/json_cache_store.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_data_source.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(
      {required AccountRemoteDataSource remote, required JsonCacheStore cache})
      : _remote = remote,
        _cache = cache;

  static const _listCacheKey = 'binova.cache.accounts.v1';
  final AccountRemoteDataSource _remote;
  final JsonCacheStore _cache;

  @override
  Future<AccountsSnapshot> listAccounts() async {
    try {
      final accounts = await _remote.fetchAccounts();
      await _cache.write(
        _listCacheKey,
        accounts.map((account) => account.toMap()).toList(),
      );
      return AccountsSnapshot(
        accounts: accounts,
        fetchedAt: DateTime.now(),
        isStale: false,
      );
    } on Object {
      final cached = await _cache.read(_listCacheKey);
      if (cached == null || cached.payload is! List) rethrow;
      final accounts = (cached.payload as List)
          .whereType<Map>()
          .map((item) => Account.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);
      return AccountsSnapshot(
        accounts: accounts,
        fetchedAt: cached.fetchedAt,
        isStale: true,
      );
    }
  }

  @override
  Future<AccountSnapshot> getAccount(String id) async {
    final key = 'binova.cache.account.v1.$id';
    try {
      final account = await _remote.fetchAccount(id);
      await _cache.write(key, account.toMap());
      return AccountSnapshot(
        account: account,
        fetchedAt: DateTime.now(),
        isStale: false,
      );
    } on Object {
      final cached = await _cache.read(key);
      if (cached == null || cached.payload is! Map) rethrow;
      return AccountSnapshot(
        account:
            Account.fromMap(Map<String, dynamic>.from(cached.payload as Map)),
        fetchedAt: cached.fetchedAt,
        isStale: true,
      );
    }
  }
}
