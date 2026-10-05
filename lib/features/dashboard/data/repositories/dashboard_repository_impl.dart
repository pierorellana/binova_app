import '../../../../core/storage/json_cache_store.dart';
import '../../domain/entities/dashboard_config.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(
      {required DashboardRemoteDataSource remote,
      required JsonCacheStore cache})
      : _remote = remote,
        _cache = cache;

  static const _cacheKey = 'binova.cache.dashboard.v1';
  final DashboardRemoteDataSource _remote;
  final JsonCacheStore _cache;

  @override
  Future<DashboardSnapshot> getDashboard() async {
    try {
      final config = await _remote.fetch();
      await _cache.write(
          _cacheKey,
          <String, dynamic>{
            'schemaVersion': config.schemaVersion,
            'segment': config.segment,
            'sections': config.sections
                .map(
                  (section) => <String, dynamic>{
                    'id': section.id,
                    'type': _typeName(section.type),
                    'order': section.order,
                    'payload': section.payload,
                  },
                )
                .toList(),
          },
          schemaVersion: config.schemaVersion);
      return DashboardSnapshot(
        config: config,
        fetchedAt: DateTime.now(),
        isStale: false,
      );
    } on Object {
      final cached = await _cache.read(_cacheKey);
      if (cached == null || cached.payload is! Map) rethrow;
      return DashboardSnapshot(
        config: DashboardConfig.fromMap(
            Map<String, dynamic>.from(cached.payload as Map)),
        fetchedAt: cached.fetchedAt,
        isStale: true,
      );
    }
  }

  String _typeName(DashboardSectionType type) {
    return switch (type) {
      DashboardSectionType.balance => 'balance',
      DashboardSectionType.quickActions => 'quick_actions',
      DashboardSectionType.products => 'products',
      DashboardSectionType.recentTransactions => 'recent_transactions',
      DashboardSectionType.insight => 'insight',
      DashboardSectionType.exchangePromo => 'exchange_promo',
      DashboardSectionType.serviceStatus => 'service_status',
    };
  }
}
