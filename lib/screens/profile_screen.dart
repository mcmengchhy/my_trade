import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/achievement_badge.dart';
import '../providers/challenges_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_palette.dart';
import '../utils/challenge_math.dart';
import '../widgets/badge_card.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && context.mounted) {
      await context.read<ProfileProvider>().setName(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final profile = context.watch<ProfileProvider>().profile;
    final challenges = context.watch<ChallengesProvider>().challenges;
    final name = profile?.name ?? 'Trader';

    final achieved = challenges.where((c) => challengeStatus(c) == ChallengeStatus.achieved).length;
    final active = challenges.where((c) => challengeStatus(c) == ChallengeStatus.active).length;
    final netPnl = challenges.fold<double>(0, (sum, c) => sum + (c.currentBalance - c.startBalance));

    final level = profile?.level ?? 1;
    final levelTitle = profile?.levelTitle ?? 'Novice Trader';
    final xpInLevel = profile?.xpInCurrentLevel ?? 0;
    final totalXp = profile?.xp ?? 0;
    final progress = profile?.progressToNextLevel ?? 0.0;
    final unlockedBadges = Set<String>.from(profile?.unlockedBadges ?? []);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                UserAvatar(name: name, radius: 44),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _editName(context, name),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit_rounded, size: 18, color: palette.mutedInk),
                    ],
                  ),
                ),
                if (profile != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Trading since ${DateFormat.yMMMd().format(profile.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          // XP & Level Progression Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Lvl $level',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            levelTitle,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        '$totalXp XP',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$xpInLevel / 250 XP to Level ${level + 1}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: StatTile(label: 'Challenges', value: '${challenges.length}')),
              const SizedBox(width: 12),
              Expanded(child: StatTile(label: 'Active', value: '$active')),
              const SizedBox(width: 12),
              Expanded(child: StatTile(label: 'Achieved', value: '$achieved')),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total net P/L', style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    '${netPnl >= 0 ? '+' : ''}\$${netPnl.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: netPnl >= 0 ? palette.statusGood : palette.statusCritical,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(icon: Icons.widgets_rounded, label: 'Home Screen Widget'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Home Widget', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Sync balance & daily pace to phone home screen'),
                    value: context.watch<ChallengesProvider>().isWidgetEnabled,
                    onChanged: (val) {
                      context.read<ChallengesProvider>().setWidgetEnabled(val);
                    },
                  ),
                  if (context.watch<ChallengesProvider>().isWidgetEnabled) ...[
                    const Divider(height: 1),
                    Builder(
                      builder: (context) {
                        final rawSelectedId = context.watch<ChallengesProvider>().selectedWidgetChallengeId;
                        final selectedId = challenges.any((c) => c.id == rawSelectedId) ? rawSelectedId : null;
                        return ListTile(
                          title: const Text('Displayed Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Select which challenge features on the widget'),
                          trailing: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: selectedId,
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Auto (First Active)', style: TextStyle(fontSize: 13)),
                                ),
                                for (final c in challenges)
                                  DropdownMenuItem<String?>(
                                    value: c.id,
                                    child: Text(c.name, style: const TextStyle(fontSize: 13)),
                                  ),
                              ],
                              onChanged: (id) {
                                context.read<ChallengesProvider>().setSelectedWidgetChallengeId(id);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(icon: Icons.military_tech_rounded, label: 'Achievements & Badges'),
          const SizedBox(height: 12),
          for (final badge in AchievementBadge.allBadges) ...[
            BadgeCard(
              badge: badge,
              isUnlocked: unlockedBadges.contains(badge.id),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
