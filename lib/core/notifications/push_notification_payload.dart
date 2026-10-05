import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationPayload {
  const PushNotificationPayload({
    required this.type,
    required this.notificationId,
    this.resourceType,
    this.resourceId,
    this.title,
    this.body,
  });

  final String type;
  final String notificationId;
  final String? resourceType;
  final String? resourceId;
  final String? title;
  final String? body;

  factory PushNotificationPayload.fromRemoteMessage(RemoteMessage message) =>
      PushNotificationPayload.fromMap(
        message.data,
        title: message.notification?.title,
        body: message.notification?.body,
      );

  factory PushNotificationPayload.fromMap(
    Map<String, dynamic> map, {
    String? title,
    String? body,
  }) {
    final type = map['type'];
    final notificationId = map['notificationId'];
    final resourceType = map['resourceType'];
    final resourceId = map['resourceId'];
    if (type is! String ||
        !{'financial', 'security', 'informational'}.contains(type) ||
        notificationId is! String ||
        notificationId.isEmpty ||
        (resourceType != null && resourceType is! String) ||
        (resourceId != null && resourceId is! String)) {
      throw const FormatException('Invalid push notification payload.');
    }
    return PushNotificationPayload(
      type: type,
      notificationId: notificationId,
      resourceType: resourceType as String?,
      resourceId: resourceId as String?,
      title: title,
      body: body,
    );
  }

  factory PushNotificationPayload.fromEncoded(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException('Invalid encoded push notification payload.');
    }
    return PushNotificationPayload.fromMap(
      Map<String, dynamic>.from(decoded),
    );
  }

  Map<String, String> toData() => <String, String>{
        'type': type,
        'notificationId': notificationId,
        if (resourceType != null) 'resourceType': resourceType!,
        if (resourceId != null) 'resourceId': resourceId!,
      };

  String encode() => jsonEncode(toData());
}
