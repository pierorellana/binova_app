import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/entities/session.dart';

abstract interface class SecureSessionStore {
  Future<Session?> read();
  Future<void> write(Session session);
  Future<void> clear();
}

class FlutterSecureSessionStore implements SecureSessionStore {
  FlutterSecureSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'binova.session.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<Session?> read() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      return Session.fromMap(Map<String, dynamic>.from(map));
    } on Object {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(Session session) {
    return _storage.write(key: _sessionKey, value: jsonEncode(session.toMap()));
  }

  @override
  Future<void> clear() => _storage.delete(key: _sessionKey);
}
