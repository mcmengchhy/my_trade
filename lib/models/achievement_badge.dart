import 'package:flutter/material.dart';

class AchievementBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int xpReward;

  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
  });

  static const List<AchievementBadge> allBadges = [
    AchievementBadge(
      id: 'rule_master',
      title: 'Rule Master',
      description: 'Log 3 trades adhering to your trading plan',
      icon: Icons.verified_user_rounded,
      xpReward: 200,
    ),
    AchievementBadge(
      id: 'zen_trader',
      title: 'Zen Trader',
      description: 'Log 3 trades with a Calm mindset',
      icon: Icons.self_improvement_rounded,
      xpReward: 150,
    ),
    AchievementBadge(
      id: 'journal_pro',
      title: 'Journal Pro',
      description: 'Document reflection lessons on 3 trades',
      icon: Icons.menu_book_rounded,
      xpReward: 150,
    ),
    AchievementBadge(
      id: 'streak_hero',
      title: 'Streak Hero',
      description: 'Reach a 3-day profit streak',
      icon: Icons.local_fire_department_rounded,
      xpReward: 300,
    ),
    AchievementBadge(
      id: 'first_victory',
      title: 'First Victory',
      description: 'Successfully complete a trade challenge',
      icon: Icons.emoji_events_rounded,
      xpReward: 500,
    ),
  ];

  static AchievementBadge byId(String id) {
    return allBadges.firstWhere(
      (b) => b.id == id,
      orElse: () => AchievementBadge(
        id: id,
        title: id,
        description: 'Achievement unlocked',
        icon: Icons.star_rounded,
        xpReward: 100,
      ),
    );
  }
}
