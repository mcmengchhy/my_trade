import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/challenge.dart';
import '../providers/challenges_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_palette.dart';
import '../utils/challenge_math.dart';
import '../widgets/challenge_card.dart';
import '../widgets/user_avatar.dart';
import 'challenge_detail_screen.dart';
import 'challenge_form_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final challenges = context.read<ChallengesProvider>().challenges;
      context.read<ProfileProvider>().evaluateBadges(challenges);
    });
  }

  int _statusRank(Challenge c) {
    switch (challengeStatus(c)) {
      case ChallengeStatus.active:
        return 0;
      case ChallengeStatus.achieved:
        return 1;
      case ChallengeStatus.failed:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenges = context.watch<ChallengesProvider>().challenges;
    final sorted = [...challenges]
      ..sort((a, b) {
        final rankDiff = _statusRank(a) - _statusRank(b);
        if (rankDiff != 0) return rankDiff;
        return b.startDate.compareTo(a.startDate);
      });
    final activeCount = challenges.where((c) => challengeStatus(c) == ChallengeStatus.active).length;
    final profile = context.watch<ProfileProvider>().profile;
    final userName = profile?.name ?? 'Trader';
    final userLevel = profile?.level ?? 1;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Trade Journey'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Lvl $userLevel',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      UserAvatar(name: userName, radius: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (challenges.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  activeCount == 1 ? '1 challenge in progress' : '$activeCount challenges in progress',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.palette.mutedInk),
                ),
              ),
            ),
          if (sorted.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(onCreate: () => _createChallenge(context)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              sliver: SliverList.separated(
                itemCount: sorted.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final challenge = sorted[index];
                  return ChallengeCard(
                    challenge: challenge,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChallengeDetailScreen(challengeId: challenge.id),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createChallenge(context),
        icon: const Icon(Icons.add),
        label: const Text('New challenge'),
      ),
    );
  }

  void _createChallenge(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChallengeFormScreen()),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.candlestick_chart_rounded, size: 44, color: scheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No trade challenges yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a challenge like "\$10 → \$1000 in 20 days" and track your daily trades on an activity calendar.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create your first challenge'),
            ),
          ],
        ),
      ),
    );
  }
}
