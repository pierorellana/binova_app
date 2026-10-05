import '../../../../core/storage/json_cache_store.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(
      {required NotificationRemoteDataSource remote,
      required JsonCacheStore cache})
      : _remote = remote,
        _cache = cache;

  static const _cacheKey = 'binova.cache.notifications.v1';
  final NotificationRemoteDataSource _remote;
  final JsonCacheStore _cache;

  @override
  Future<NotificationsPage> listNotifications(
      {String? cursor, bool unreadOnly = false}) async {
    final isFirstPage = cursor == null && !unreadOnly;
    try {
      final page = await _remote.fetchNotifications(
          cursor: cursor, unreadOnly: unreadOnly);
      if (isFirstPage) {
        await _cache.write(
          _cacheKey,
          <String, dynamic>{
            'items': page.items.map((item) => item.toMap()).toList(),
            'nextCursor': page.nextCursor,
          },
        );
      }
      return page;
    } on Object {
      if (!isFirstPage) rethrow;
      final cached = await _cache.read(_cacheKey);
      if (cached == null || cached.payload is! Map) rethrow;
      final payload = Map<String, dynamic>.from(cached.payload as Map);
      final rawItems = payload['items'];
      if (rawItems is! List) rethrow;
      return NotificationsPage(
        items: rawItems
            .whereType<Map>()
            .map((item) =>
                AppNotification.fromMap(Map<String, dynamic>.from(item)))
            .toList(growable: false),
        nextCursor: payload['nextCursor'] as String?,
        fetchedAt: cached.fetchedAt,
        isStale: true,
      );
    }
  }

  @override
  Future<AppNotification> markRead(String id) => _remote.markRead(id);

  @override
  Future<void> markAllRead() => _remote.markAllRead();
}
