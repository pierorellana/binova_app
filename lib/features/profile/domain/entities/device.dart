enum DevicePlatform { ios, android }

class Device {
  const Device({
    required this.id,
    required this.platform,
    required this.deviceLabel,
    required this.lastSeenAt,
    required this.active,
  });

  final String id;
  final DevicePlatform platform;
  final String deviceLabel;
  final DateTime lastSeenAt;
  final bool active;

  factory Device.fromMap(Map<String, dynamic> map) {
    if (map['id'] is! String ||
        map['platform'] is! String ||
        map['deviceLabel'] is! String ||
        map['lastSeenAt'] is! String ||
        map['active'] is! bool) {
      throw const FormatException('Invalid device.');
    }
    return Device(
      id: map['id'] as String,
      platform: switch (map['platform']) {
        'ios' => DevicePlatform.ios,
        'android' => DevicePlatform.android,
        _ => throw const FormatException('Invalid device platform.'),
      },
      deviceLabel: map['deviceLabel'] as String,
      lastSeenAt: DateTime.parse(map['lastSeenAt'] as String),
      active: map['active'] as bool,
    );
  }
}
