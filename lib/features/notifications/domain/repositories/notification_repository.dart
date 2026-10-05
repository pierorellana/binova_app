import '../entities/notification.dart';

class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.nextCursor,
    required this.fetchedAt,
    required this.isStale,
  });

  final List<AppNotification> items;
  final String? nextCursor;
  final DateTime fetchedAt;
  final bool isStale;
}

abstract interface class NotificationRepository {
  Future<NotificationsPage> listNotifications(
      {String? cursor, bool unreadOnly});
  Future<AppNotification> markRead(String id);
  Future<void> markAllRead();
}
