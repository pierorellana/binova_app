import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../app/routing/push_navigation_coordinator.dart';
import '../../features/notifications/domain/notification_link.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../firebase_options.dart';
import '../storage/push_registration_store.dart';
import 'push_notification_payload.dart';

abstract interface class PushRegistrationCoordinator {
  Future<void> activate();
  Future<void> deactivate();
}

class NoopPushRegistrationCoordinator implements PushRegistrationCoordinator {
  const NoopPushRegistrationCoordinator();

  @override
  Future<void> activate() async {}

  @override
  Future<void> deactivate() async {}
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
}

class PushNotificationService implements PushRegistrationCoordinator {
  PushNotificationService({
    required ProfileRepository profileRepository,
    required NotificationRepository notificationRepository,
    required PushRegistrationStore registrationStore,
    required PushNavigationCoordinator navigation,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    TargetPlatform? platform,
  })  : _profileRepository = profileRepository,
        _notificationRepository = notificationRepository,
        _registrationStore = registrationStore,
        _navigation = navigation,
        _messaging = messaging ??
            ((platform ?? defaultTargetPlatform) == TargetPlatform.android
                ? FirebaseMessaging.instance
                : null),
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin(),
        _platform = platform ?? defaultTargetPlatform;

  static const _channelId = 'binova_general';
  static const _channelName = 'BInova';
  static const _channelDescription = 'Notificaciones generales de BInova';

  final ProfileRepository _profileRepository;
  final NotificationRepository _notificationRepository;
  final PushRegistrationStore _registrationStore;
  final PushNavigationCoordinator _navigation;
  final FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final TargetPlatform _platform;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _active = false;

  @override
  Future<void> activate() async {
    if (_platform != TargetPlatform.android || _active) return;
    final messaging = _messaging;
    if (messaging == null) return;
    await _initializeLocalNotifications();
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    await _registerCurrentToken();
    _subscriptions.add(
      messaging.onTokenRefresh.listen(_onTokenRefresh),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen(_onForegroundMessage),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp),
    );
    final initialMessage = await messaging.getInitialMessage();
    _active = true;
    if (initialMessage != null) _onMessageOpenedApp(initialMessage);
  }

  @override
  Future<void> deactivate() async {
    if (!_active && _platform != TargetPlatform.android) return;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    final deviceId = await _registrationStore.readDeviceId();
    if (deviceId != null) {
      try {
        await _profileRepository.revokeDevice(deviceId);
      } on Object {
        await _registrationStore.clearDeviceId();
        _active = false;
        return;
      }
    }
    await _registrationStore.clearDeviceId();
    _active = false;
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_binova'),
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationResponse,
    );
    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _registerCurrentToken() async {
    final messaging = _messaging;
    if (messaging == null) return;
    final token = await messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _registerToken(token);
  }

  void _onTokenRefresh(String token) {
    unawaited(_registerToken(token));
  }

  Future<void> _registerToken(String token) async {
    final previousDeviceId = await _registrationStore.readDeviceId();
    if (previousDeviceId != null) {
      try {
        await _profileRepository.revokeDevice(previousDeviceId);
      } on Object {
        return;
      }
    }
    final device = await _profileRepository.registerDevice(
      platform: 'android',
      pushToken: token,
      deviceLabel: 'Android BInova',
    );
    await _registrationStore.writeDeviceId(device.id);
  }

  void _onForegroundMessage(RemoteMessage message) {
    unawaited(_showForegroundNotification(message));
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final payload = _payloadFromMessage(message);
    if (payload == null) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        icon: 'ic_stat_binova',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'BInova',
      ),
    );
    await _localNotifications.show(
      id: payload.notificationId.hashCode & 0x7fffffff,
      title: payload.title ?? 'BInova',
      body: payload.body ?? 'Tienes una novedad en BInova.',
      notificationDetails: details,
      payload: payload.encode(),
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    final payload = _payloadFromMessage(message);
    if (payload != null) unawaited(_openPayload(payload));
  }

  void _onLocalNotificationResponse(NotificationResponse response) {
    final encoded = response.payload;
    if (encoded == null || encoded.isEmpty) return;
    try {
      final payload = PushNotificationPayload.fromEncoded(encoded);
      unawaited(_openPayload(payload));
    } on FormatException {
      _navigation.openHome();
    }
  }

  Future<void> _openPayload(PushNotificationPayload payload) async {
    final link = NotificationLink.fromPayload(payload);
    if (link == null) {
      _navigation.openHome();
      return;
    }
    try {
      await _notificationRepository.markRead(payload.notificationId);
    } on Object {
      _navigation.openPayload(payload);
      return;
    }
    _navigation.openPayload(payload);
  }

  PushNotificationPayload? _payloadFromMessage(RemoteMessage message) {
    try {
      return PushNotificationPayload.fromRemoteMessage(message);
    } on FormatException {
      return null;
    }
  }
}
