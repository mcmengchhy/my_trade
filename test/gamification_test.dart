import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_game/models/achievement_badge.dart';
import 'package:task_game/models/trade_entry.dart';
import 'package:task_game/models/user_profile.dart';
import 'package:task_game/providers/challenges_provider.dart';
import 'package:task_game/providers/profile_provider.dart';
import 'package:task_game/theme/app_theme.dart';
import 'package:task_game/widgets/badge_card.dart';

void main() {
  group('Gamification System Tests', () {
    test('UserProfile XP and Level progression logic', () {
      final user = UserProfile(name: 'Trader', createdAt: DateTime.now(), xp: 350);
      expect(user.level, 2);
      expect(user.levelTitle, 'Apprentice Trader');
      expect(user.xpInCurrentLevel, 100);
      expect(user.xpRequiredForNextLevel, 250);
      expect(user.progressToNextLevel, 0.4);
    });

    test('ProfileProvider XP addition and badge evaluation', () async {
      SharedPreferences.setMockInitialValues({});
      final challengesProvider = ChallengesProvider();
      await challengesProvider.load();
      final profileProvider = ProfileProvider();
      await profileProvider.load();

      await profileProvider.setName('Gamified Trader');
      expect(profileProvider.profile?.xp, 0);
      expect(profileProvider.profile?.level, 1);

      // Add 250 XP
      await profileProvider.addXp(250);
      expect(profileProvider.profile?.xp, 250);
      expect(profileProvider.profile?.level, 2);

      // Create challenge & trades to unlock "rule_master" badge (3 trades with plan followed)
      await challengesProvider.addChallenge(
        name: 'Badge Test Challenge',
        startBalance: 100,
        targetBalance: 500,
        durationDays: 20,
        startDate: DateTime.now(),
      );
      final challengeId = challengesProvider.challenges.first.id;

      for (var i = 0; i < 3; i++) {
        await challengesProvider.addTrade(
          challengeId,
          TradeEntry(
            id: 't_$i',
            date: DateTime.now().add(Duration(days: i)),
            pnl: 10.0,
            followedPlan: true,
            emotion: 'Calm',
            lesson: 'Followed strategy step by step',
          ),
        );
      }

      final newlyUnlocked = await profileProvider.evaluateBadges(challengesProvider.challenges);
      expect(newlyUnlocked.any((b) => b.id == 'rule_master'), isTrue);
      expect(profileProvider.profile?.unlockedBadges.contains('rule_master'), isTrue);
    });

    testWidgets('BadgeCard renders unlocked and locked states properly', (tester) async {
      const badge = AchievementBadge(
        id: 'rule_master',
        title: 'Rule Master',
        description: 'Log 3 trades adhering to plan',
        icon: Icons.verified_user_rounded,
        xpReward: 200,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ListView(
              children: const [
                BadgeCard(badge: badge, isUnlocked: true),
                BadgeCard(badge: badge, isUnlocked: false),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Rule Master'), findsNWidgets(2));
      expect(find.text('+200 XP'), findsNWidgets(2));
    });
  });
}
