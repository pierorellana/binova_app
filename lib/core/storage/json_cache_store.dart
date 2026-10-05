import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CachedJson {
  const CachedJson({
    required this.payload,
    required this.fetchedAt,
    required this.schemaVersion,
  });

  final dynamic payload;
  final DateTime fetchedAt;
  final int schemaVersion;

  bool get isFresh =>
      DateTime.now().difference(fetchedAt) < const Duration(seconds: 60);
}

abstract interface class JsonCacheStore {
  Future<CachedJson?> read(String key);
  Future<void> write(String key, dynamic payload, {int schemaVersion = 1});
  Future<void> clear(String key);
}

class SharedPreferencesJsonCacheStore implements JsonCacheStore {
  SharedPreferencesJsonCacheStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<CachedJson?> read(String key) async {
    final raw = _preferences.getString(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      return CachedJson(
        payload: map['payload'],
        fetchedAt: DateTime.parse(map['fetchedAt'] as String),
        schemaVersion: map['schemaVersion'] as int? ?? 1,
      );
    } on Object {
      await clear(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, dynamic payload, {int schemaVersion = 1}) {
    return _preferences.setString(
      key,
      jsonEncode(<String, dynamic>{
        'payload': payload,
        'fetchedAt': DateTime.now().toIso8601String(),
        'schemaVersion': schemaVersion,
      }),
    );
  }

  @override
  Future<void> clear(String key) => _preferences.remove(key);
}
