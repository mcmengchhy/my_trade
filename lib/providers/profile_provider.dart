import 'package:flutter/foundation.dart';

import '../models/achievement_badge.dart';
import '../models/challenge.dart';
import '../models/user_profile.dart';
import '../services/home_widget_service.dart';
import '../services/storage_service.dart';
import '../utils/challenge_math.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({StorageService? storage}) : _storage = storage ?? StorageService();

  final StorageService _storage;
  UserProfile? _profile;
  bool _isLoaded = false;

  UserProfile? get profile => _profile;
  bool get isLoaded => _isLoaded;
  bool get hasProfile => _profile != null && _profile!.name.trim().isNotEmpty;

  Future<void> _syncHomeWidget() async {
    try {
      await HomeWidgetService.syncData(profile: _profile, syncChallenge: false);
    } catch (_) {}
  }

  Future<void> load() async {
    _profile = await _storage.loadProfile();
    _isLoaded = true;
    notifyListeners();
    _syncHomeWidget().catchError((_) {});
  }

  Future<void> setName(String name) async {
    final trimmed = name.trim();
    if (_profile == null) {
      _profile = UserProfile(name: trimmed, createdAt: DateTime.now());
    } else {
      _profile = _profile!.copyWith(name: trimmed);
    }
    notifyListeners();
    await _storage.saveProfile(_profile!);
    await _syncHomeWidget();
  }

  Future<int> addXp(int amount) async {
    if (_profile == null) return 0;
    final newXp = _profile!.xp + amount;
    _profile = _profile!.copyWith(xp: newXp);
    notifyListeners();
    await _storage.saveProfile(_profile!);
    await _syncHomeWidget();
    return amount;
  }

  /// Evaluates all badges against the given list of challenges and unlocks
  /// any badges whose requirements have been fulfilled.
  /// Returns a list of newly unlocked achievement badges.
  Future<List<AchievementBadge>> evaluateBadges(List<Challenge> challenges) async {
    if (_profile == null) return [];

    final currentBadges = Set<String>.from(_profile!.unlockedBadges);
    final newlyUnlocked = <AchievementBadge>[];

    final allTrades = challenges.expand((c) => c.trades).toList();

    // 1. rule_master: 3 trades with plan followed
    if (!currentBadges.contains('rule_master')) {
      final followedCount = allTrades.where((t) => t.followedPlan == true).length;
      if (followedCount >= 3) {
        newlyUnlocked.add(AchievementBadge.byId('rule_master'));
      }
    }

    // 2. zen_trader: 3 trades with Calm emotion
    if (!currentBadges.contains('zen_trader')) {
      final calmCount = allTrades.where((t) => t.emotion == 'Calm').length;
      if (calmCount >= 3) {
        newlyUnlocked.add(AchievementBadge.byId('zen_trader'));
      }
    }

    // 3. journal_pro: 3 trades with lessons written
    if (!currentBadges.contains('journal_pro')) {
      final lessonCount = allTrades.where((t) => t.lesson != null && t.lesson!.trim().isNotEmpty).length;
      if (lessonCount >= 3) {
        newlyUnlocked.add(AchievementBadge.byId('journal_pro'));
      }
    }

    // 4. streak_hero: 3-day profit streak
    if (!currentBadges.contains('streak_hero')) {
      final hasStreak = challenges.any((c) => currentProfitStreak(c) >= 3);
      if (hasStreak) {
        newlyUnlocked.add(AchievementBadge.byId('streak_hero'));
      }
    }

    // 5. first_victory: achieve a challenge goal
    if (!currentBadges.contains('first_victory')) {
      final hasAchieved = challenges.any((c) => challengeStatus(c) == ChallengeStatus.achieved);
      if (hasAchieved) {
        newlyUnlocked.add(AchievementBadge.byId('first_victory'));
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      final updatedBadges = Set<String>.from(currentBadges)
        ..addAll(newlyUnlocked.map((b) => b.id));
      final extraXp = newlyUnlocked.fold<int>(0, (sum, b) => sum + b.xpReward);

      _profile = _profile!.copyWith(
        xp: _profile!.xp + extraXp,
        unlockedBadges: updatedBadges.toList(),
      );
      notifyListeners();
      await _storage.saveProfile(_profile!);
      await _syncHomeWidget();
    }

    return newlyUnlocked;
  }
}
