class User {
  User({
    required String id,
    required String email,
    required String displayName,
    required String segment,
  })  : id = _validatedValue(id, 'id'),
        email = _validatedValue(email, 'email'),
        displayName = _validatedValue(displayName, 'displayName'),
        segment = _validatedValue(segment, 'segment');

  final String id;
  final String email;
  final String displayName;
  final String segment;

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: _requiredString(map, 'id'),
      email: _requiredString(map, 'email'),
      displayName: _requiredString(map, 'displayName'),
      segment: _requiredString(map, 'segment'),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'email': email,
        'displayName': displayName,
        'segment': segment,
      };

  Map<String, dynamic> toJson() => toMap();

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? segment,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      segment: segment ?? this.segment,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.segment == segment;
  }

  @override
  int get hashCode => Object.hash(id, email, displayName, segment);

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing or invalid User.$key');
    }
    return value;
  }

  static String _validatedValue(String value, String key) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, key, 'must not be empty');
    }
    return value;
  }
}
