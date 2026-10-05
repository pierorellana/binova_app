class ProfilePreferences {
  const ProfilePreferences({
    required this.hideBalance,
    required this.reduceMotion,
    required this.notificationsEnabled,
  });

  final bool hideBalance;
  final bool reduceMotion;
  final bool notificationsEnabled;

  factory ProfilePreferences.fromMap(Map<String, dynamic> map) {
    if (map['hideBalance'] is! bool ||
        map['reduceMotion'] is! bool ||
        map['notificationsEnabled'] is! bool) {
      throw const FormatException('Invalid profile preferences.');
    }
    return ProfilePreferences(
      hideBalance: map['hideBalance'] as bool,
      reduceMotion: map['reduceMotion'] as bool,
      notificationsEnabled: map['notificationsEnabled'] as bool,
    );
  }

  ProfilePreferences copyWith({
    bool? hideBalance,
    bool? reduceMotion,
    bool? notificationsEnabled,
  }) {
    return ProfilePreferences(
      hideBalance: hideBalance ?? this.hideBalance,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'hideBalance': hideBalance,
        'reduceMotion': reduceMotion,
        'notificationsEnabled': notificationsEnabled,
      };
}
