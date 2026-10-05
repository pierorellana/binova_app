import 'package:flutter/material.dart';

import '../../core/notifications/push_notification_payload.dart';
import '../../features/notifications/domain/notification_link.dart';
import 'app_router.dart';

class PushNavigationCoordinator {
  final navigatorKey = GlobalKey<NavigatorState>();

  void openPayload(PushNotificationPayload payload) {
    final link = NotificationLink.fromPayload(payload);
    if (link == null) {
      openHome();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamed(
        link.route,
        arguments: link.argument,
      );
    });
  }

  void openHome() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoute.home,
        (_) => false,
      );
    });
  }
}
