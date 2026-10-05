import '../../../../core/storage/json_cache_store.dart';
import '../../domain/entities/insights.dart';
import '../../domain/repositories/insights_repository.dart';
import '../datasources/insights_remote_data_source.dart';

class InsightsRepositoryImpl implements InsightsRepository {
  InsightsRepositoryImpl(
      {required InsightsRemoteDataSource remote, required JsonCacheStore cache})
      : _remote = remote,
        _cache = cache;

  static const _cacheKey = 'binova.cache.insights.month.v1';
  final InsightsRemoteDataSource _remote;
  final JsonCacheStore _cache;

  @override
  Future<InsightsSnapshot> getMonthlyInsights() async {
    try {
      final insights = await _remote.fetchMonthly();
      await _cache.write(_cacheKey, insights.toMap());
      return InsightsSnapshot(
        insights: insights,
        fetchedAt: DateTime.now(),
        isStale: false,
      );
    } on Object {
      final cached = await _cache.read(_cacheKey);
      if (cached == null || cached.payload is! Map) rethrow;
      return InsightsSnapshot(
        insights:
            Insights.fromMap(Map<String, dynamic>.from(cached.payload as Map)),
        fetchedAt: cached.fetchedAt,
        isStale: true,
      );
    }
  }
}
