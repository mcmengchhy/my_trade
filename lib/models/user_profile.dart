class UserProfile {
  final String name;
  final DateTime createdAt;
  final int xp;
  final List<String> unlockedBadges;

  const UserProfile({
    required this.name,
    required this.createdAt,
    this.xp = 0,
    List<String>? unlockedBadges,
  }) : unlockedBadges = unlockedBadges ?? const [];

  int get level => (xp / 250).floor() + 1;
  int get xpInCurrentLevel => xp % 250;
  int get xpRequiredForNextLevel => 250;
  double get progressToNextLevel => (xpInCurrentLevel / 250).clamp(0.0, 1.0);

  String get levelTitle {
    if (level >= 10) return 'Master Trader';
    if (level >= 7) return 'Senior Trader';
    if (level >= 4) return 'Disciplined Trader';
    if (level >= 2) return 'Apprentice Trader';
    return 'Novice Trader';
  }

  UserProfile copyWith({
    String? name,
    DateTime? createdAt,
    int? xp,
    List<String>? unlockedBadges,
  }) {
    return UserProfile(
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      xp: xp ?? this.xp,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'xp': xp,
        'unlockedBadges': unlockedBadges,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        unlockedBadges: (json['unlockedBadges'] as List<dynamic>?)?.cast<String>() ?? const [],
      );
}
