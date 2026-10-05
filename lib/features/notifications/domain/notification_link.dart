import '../../../app/routing/app_router.dart';
import '../../../core/notifications/push_notification_payload.dart';
import 'entities/notification.dart';

class NotificationLink {
  const NotificationLink(this.label, this.route, [this.argument]);

  final String label;
  final String route;
  final Object? argument;

  static NotificationLink? fromNotification(AppNotification notification) {
    final id = notification.resourceId;
    if (id != null) {
      switch (notification.resourceType) {
        case 'transaction':
          return NotificationLink(
              'Ver movimiento', AppRoute.transactionDetail, id);
        case 'account':
          return NotificationLink('Ver cuenta', AppRoute.accountDetail, id);
        case 'card':
          return NotificationLink('Ver tarjeta', AppRoute.cardDetail, id);
      }
    }
    return switch (notification.type) {
      NotificationType.informational =>
        const NotificationLink('Abrir Insights', AppRoute.insights),
      NotificationType.security when !_asksConfirmation(notification) =>
        const NotificationLink('Ir a Perfil', AppRoute.profile),
      _ => null,
    };
  }

  static NotificationLink? fromPayload(PushNotificationPayload payload) {
    final id = payload.resourceId;
    if (id != null) {
      switch (payload.resourceType) {
        case 'transaction':
          return NotificationLink(
              'Ver movimiento', AppRoute.transactionDetail, id);
        case 'account':
          return NotificationLink('Ver cuenta', AppRoute.accountDetail, id);
        case 'card':
          return NotificationLink('Ver tarjeta', AppRoute.cardDetail, id);
        case 'session':
          return const NotificationLink('Ir a Perfil', AppRoute.profile);
      }
    }
    return switch (payload.type) {
      'informational' =>
        const NotificationLink('Abrir Insights', AppRoute.insights),
      'security' => const NotificationLink('Ir a Perfil', AppRoute.profile),
      _ => null,
    };
  }

  static bool _asksConfirmation(AppNotification notification) =>
      notification.type == NotificationType.security &&
      (notification.resourceType == 'session' ||
          notification.body.contains('¿Fuiste tú?'));
}
