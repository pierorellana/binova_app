import '../../../../core/storage/json_cache_store.dart';
import '../../domain/entities/exchange_rate.dart';
import '../../domain/repositories/exchange_rate_repository.dart';
import '../datasources/exchange_rate_remote_data_source.dart';

class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  ExchangeRateRepositoryImpl({
    required ExchangeRateRemoteDataSource remote,
    required JsonCacheStore cache,
  })  : _remote = remote,
        _cache = cache;

  static const _cachePrefix = 'binova.cache.exchange-rate.v1.';
  static const _staleMaxAge = Duration(minutes: 15);

  final ExchangeRateRemoteDataSource _remote;
  final JsonCacheStore _cache;

  @override
  Future<ExchangeRateSnapshot> getRate({
    required String base,
    required String quote,
  }) async {
    final normalizedBase = base.toUpperCase();
    final normalizedQuote = quote.toUpperCase();
    final key = '$_cachePrefix$normalizedBase-$normalizedQuote';
    try {
      final rate = await _remote.fetch(
        base: normalizedBase,
        quote: normalizedQuote,
      );
      await _cache.write(key, rate.toMap());
      return ExchangeRateSnapshot(
        rate: rate,
        fetchedAt: DateTime.now(),
        isStale: rate.stale,
      );
    } on Object {
      final cached = await _cache.read(key);
      if (cached == null ||
          cached.payload is! Map ||
          DateTime.now().difference(cached.fetchedAt) > _staleMaxAge) {
        rethrow;
      }
      final cachedRate = ExchangeRate.fromMap(
          Map<String, dynamic>.from(cached.payload as Map));
      return ExchangeRateSnapshot(
        rate: cachedRate.copyWith(stale: true),
        fetchedAt: cached.fetchedAt,
        isStale: true,
      );
    }
  }
}
