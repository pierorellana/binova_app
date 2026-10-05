import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:binova_app/app/routing/app_router.dart';
import 'package:binova_app/core/notifications/push_notification_payload.dart';
import 'package:binova_app/core/storage/push_registration_store.dart';
import 'package:binova_app/features/notifications/domain/notification_link.dart';

void main() {
  test('parses an allowed transaction push payload', () {
    final payload = PushNotificationPayload.fromRemoteMessage(
      const RemoteMessage(
        data: <String, dynamic>{
          'type': 'financial',
          'notificationId': 'notification-1',
          'resourceType': 'transaction',
          'resourceId': 'transaction-1',
        },
      ),
    );

    expect(payload.type, 'financial');
    expect(payload.notificationId, 'notification-1');
    expect(payload.toData(), {
      'type': 'financial',
      'notificationId': 'notification-1',
      'resourceType': 'transaction',
      'resourceId': 'transaction-1',
    });
    expect(NotificationLink.fromPayload(payload)?.route,
        AppRoute.transactionDetail);
  });

  test('rejects malformed push payloads', () {
    expect(
      () => PushNotificationPayload.fromMap(<String, dynamic>{
        'type': 'financial',
        'notificationId': '',
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => PushNotificationPayload.fromMap(<String, dynamic>{
        'type': 'unknown',
        'notificationId': 'notification-1',
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('falls back to home for an unknown resource', () {
    const payload = PushNotificationPayload(
      type: 'financial',
      notificationId: 'notification-1',
      resourceType: 'unknown',
      resourceId: 'resource-1',
    );

    expect(NotificationLink.fromPayload(payload), isNull);
  });

  test('stores only the API device registration id', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesPushRegistrationStore(preferences);

    await store.writeDeviceId('device-1');

    expect(await store.readDeviceId(), 'device-1');
    expect(preferences.getKeys(), {'binova.push.registration.v1'});

    await store.clearDeviceId();
    expect(await store.readDeviceId(), isNull);
  });
}
