enum NotificationType { security, financial, informational }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.resourceType,
    required this.resourceId,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? resourceType;
  final String? resourceId;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    if (map['id'] is! String ||
        map['type'] is! String ||
        map['title'] is! String ||
        map['body'] is! String ||
        map['read'] is! bool ||
        map['createdAt'] is! String) {
      throw const FormatException('Invalid notification.');
    }
    return AppNotification(
      id: map['id'] as String,
      type: _type(map['type'] as String),
      title: map['title'] as String,
      body: map['body'] as String,
      resourceType: map['resourceType'] as String?,
      resourceId: map['resourceId'] as String?,
      read: map['read'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  AppNotification markRead() => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        resourceType: resourceType,
        resourceId: resourceId,
        read: true,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'resourceType': resourceType,
        'resourceId': resourceId,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
      };

  static NotificationType _type(String value) => switch (value) {
        'security' => NotificationType.security,
        'financial' => NotificationType.financial,
        'informational' => NotificationType.informational,
        _ => throw const FormatException('Invalid notification type.'),
      };
}
