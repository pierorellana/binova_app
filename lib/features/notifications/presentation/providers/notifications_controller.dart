import 'package:flutter/foundation.dart';

import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';

enum NotificationsStatus { idle, loading, loaded, offlineStale, error }

class NotificationsController extends ChangeNotifier {
  NotificationsController(this._repository);

  final NotificationRepository _repository;

  NotificationsStatus status = NotificationsStatus.idle;
  List<AppNotification> items = const <AppNotification>[];
  String? nextCursor;
  DateTime? fetchedAt;
  String? errorMessage;
  bool isMarkingAllRead = false;

  Future<void> load() async {
    status = NotificationsStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final page = await _repository.listNotifications();
      items = _unique(page.items);
      nextCursor = page.nextCursor;
      fetchedAt = page.fetchedAt;
      status = page.isStale
          ? NotificationsStatus.offlineStale
          : NotificationsStatus.loaded;
    } on Object {
      status = NotificationsStatus.error;
      errorMessage = 'No pudimos cargar tus notificaciones.';
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (nextCursor == null) return;
    try {
      final page = await _repository.listNotifications(cursor: nextCursor);
      items = _unique(<AppNotification>[...items, ...page.items]);
      nextCursor = page.nextCursor;
    } finally {
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    final updated = await _repository.markRead(id);
    items = items
        .map((item) => item.id == updated.id ? updated : item)
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> markAllRead() async {
    if (isMarkingAllRead) return;
    isMarkingAllRead = true;
    notifyListeners();
    try {
      await _repository.markAllRead();
      items = items.map((item) => item.markRead()).toList(growable: false);
    } finally {
      isMarkingAllRead = false;
      notifyListeners();
    }
  }

  List<AppNotification> _unique(Iterable<AppNotification> values) {
    final seen = <String>{};
    return values.where((item) => seen.add(item.id)).toList(growable: false);
  }
}
