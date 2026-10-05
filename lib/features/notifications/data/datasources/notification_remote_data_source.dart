import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';

abstract interface class NotificationRemoteDataSource {
  Future<NotificationsPage> fetchNotifications(
      {String? cursor, bool unreadOnly});
  Future<AppNotification> markRead(String id);
  Future<void> markAllRead();
}

class HttpNotificationRemoteDataSource implements NotificationRemoteDataSource {
  HttpNotificationRemoteDataSource(this._client);

  final AuthenticatedApiClient _client;

  @override
  Future<NotificationsPage> fetchNotifications(
      {String? cursor, bool unreadOnly = false}) async {
    final response = await _client.get(
      '/notifications',
      queryParameters: <String, String?>{
        'cursor': cursor,
        'unreadOnly': unreadOnly.toString(),
      },
    );
    if (response.data is! List) {
      throw const FormatException('Invalid notifications payload.');
    }
    return NotificationsPage(
      items: (response.data as List)
          .whereType<Map>()
          .map((item) =>
              AppNotification.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      nextCursor: response.meta['nextCursor'] as String?,
      fetchedAt: DateTime.now(),
      isStale: false,
    );
  }

  @override
  Future<AppNotification> markRead(String id) async {
    final response = await _client.post('/notifications/$id/read');
    if (response.data is! Map) {
      throw const FormatException('Invalid notification payload.');
    }
    return AppNotification.fromMap(
        Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<void> markAllRead() async {
    await _client.post('/notifications/read-all');
  }
}
