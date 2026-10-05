import 'user.dart';

class Session {
  Session({
    required String accessToken,
    required String refreshToken,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
    required this.user,
  })  : accessToken = _validatedToken(accessToken, 'accessToken'),
        refreshToken = _validatedToken(refreshToken, 'refreshToken');

  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final DateTime refreshTokenExpiresAt;
  final User user;

  bool get isAccessTokenValid =>
      DateTime.now().toUtc().isBefore(accessTokenExpiresAt.toUtc());

  bool get isRefreshTokenValid =>
      DateTime.now().toUtc().isBefore(refreshTokenExpiresAt.toUtc());

  factory Session.fromMap(Map<String, dynamic> map) {
    final rawUser = map['user'];
    if (rawUser is! Map) {
      throw const FormatException('Missing or invalid Session.user');
    }

    return Session(
      accessToken: _requiredString(map, 'accessToken'),
      refreshToken: _requiredString(map, 'refreshToken'),
      accessTokenExpiresAt: _requiredDateTime(map, 'accessTokenExpiresAt'),
      refreshTokenExpiresAt: _requiredDateTime(map, 'refreshTokenExpiresAt'),
      user: User.fromMap(Map<String, dynamic>.from(rawUser)),
    );
  }

  factory Session.fromJson(Map<String, dynamic> json) => Session.fromMap(json);

  Map<String, dynamic> toMap() => <String, dynamic>{
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'accessTokenExpiresAt': accessTokenExpiresAt.toUtc().toIso8601String(),
        'refreshTokenExpiresAt':
            refreshTokenExpiresAt.toUtc().toIso8601String(),
        'user': user.toMap(),
      };

  Map<String, dynamic> toJson() => toMap();

  @override
  bool operator ==(Object other) {
    return other is Session &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.accessTokenExpiresAt == accessTokenExpiresAt &&
        other.refreshTokenExpiresAt == refreshTokenExpiresAt &&
        other.user == user;
  }

  @override
  int get hashCode => Object.hash(
        accessToken,
        refreshToken,
        accessTokenExpiresAt,
        refreshTokenExpiresAt,
        user,
      );

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing or invalid Session.$key');
    }
    return value;
  }

  static DateTime _requiredDateTime(Map<String, dynamic> map, String key) {
    final rawValue = map[key];
    if (rawValue is! String || rawValue.isEmpty) {
      throw FormatException('Missing or invalid Session.$key');
    }
    final value = DateTime.tryParse(rawValue);
    if (value == null) {
      throw FormatException('Missing or invalid Session.$key');
    }
    return value;
  }

  static String _validatedToken(String value, String key) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, key, 'must not be empty');
    }
    return value;
  }
}
