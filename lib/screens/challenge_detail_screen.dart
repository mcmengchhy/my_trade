import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/challenge.dart';
import '../providers/challenges_provider.dart';
import '../theme/app_palette.dart';
import '../utils/challenge_math.dart';
import '../utils/performance_stats.dart' as stats;
import '../widgets/activity_heatmap.dart';
import '../widgets/balance_chart.dart';
import '../widgets/emotion_analytics_card.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';
import '../widgets/status_chip.dart';
import '../widgets/trade_tile.dart';
import 'add_trade_screen.dart';

class ChallengeDetailScreen extends StatelessWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  Future<void> _confirmDeleteChallenge(BuildContext context, Challenge challenge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete challenge?'),
        content: Text('This will permanently remove "${challenge.name}" and all its logged trades.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ChallengesProvider>().deleteChallenge(challenge.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDeleteTrade(BuildContext context, String tradeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete trade?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ChallengesProvider>().deleteTrade(challengeId, tradeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengesProvider>();
    Challenge challenge;
    try {
      challenge = provider.byId(challengeId);
    } catch (_) {
      return const Scaffold(body: Center(child: Text('Challenge not found')));
    }

    final status = challengeStatus(challenge);
    final visual = resolveStatusVisual(context, status);
    final rate = requiredDailyRate(challenge.startBalance, challenge.targetBalance, challenge.durationDays);
    final sortedTrades = [...challenge.trades]..sort((a, b) => b.date.compareTo(a.date));
    final palette = context.palette;
    final progress = progressFraction(challenge);
    final requiredToday = todaysRequiredProfit(challenge);
    final actualToday = netPnlForDay(challenge, DateTime.now());
    final paceVisual = resolvePaceVisual(context, paceStatus(challenge));
    final lossBreached = dailyLossBreached(challenge, DateTime.now());
    final adherence = planAdherence(challenge);

    return Scaffold(
      appBar: AppBar(
        title: Text(challenge.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDeleteChallenge(context, challenge),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${challenge.currentBalance.toStringAsFixed(2)}',
                        key: const Key('currentBalanceText'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      StatusChip(visual: visual),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Day ${currentDayIndex(challenge) + 1} of ${challenge.durationDays} · '
                    '\$${challenge.startBalance.toStringAsFixed(0)} → \$${challenge.targetBalance.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Color.lerp(
                        Theme.of(context).colorScheme.surface,
                        visual.color,
                        0.18,
                      ),
                      color: visual.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Requires ~${(rate * 100).toStringAsFixed(2)}% growth per day to hit target',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                  ),
                  if (status == ChallengeStatus.active) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Required today \$${requiredToday.toStringAsFixed(2)} · '
                            'Today ${actualToday >= 0 ? '+' : ''}\$${actualToday.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Icon(paceVisual.icon, size: 16, color: paceVisual.color),
                        const SizedBox(width: 4),
                        Text(
                          paceVisual.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: paceVisual.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (lossBreached == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: palette.statusCritical.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: palette.statusCritical),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Daily loss limit exceeded today',
                              style: TextStyle(color: palette.statusCritical, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (challenge.rules.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader(icon: Icons.rule_rounded, label: 'Trading rules'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    for (final rule in challenge.rules)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 18, color: palette.mutedInk),
                            const SizedBox(width: 10),
                            Expanded(child: Text(rule)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const SectionHeader(icon: Icons.show_chart_rounded, label: 'Growth vs. target pace'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BalanceChart(challenge: challenge),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(icon: Icons.calendar_view_month_rounded, label: 'Activity'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ActivityHeatmap(
                challenge: challenge,
                onDayTap: (day) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddTradeScreen(challenge: challenge, initialDate: day),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(icon: Icons.leaderboard_rounded, label: 'Performance'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Win rate',
                  value: stats.winRate(challenge) == null
                      ? 'N/A'
                      : '${stats.winRate(challenge)!.toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'Profit factor',
                  value: stats.profitFactor(challenge) == null
                      ? 'N/A'
                      : stats.profitFactor(challenge)!.toStringAsFixed(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'Plan adherence',
                  value: adherence == null ? 'N/A' : '${adherence.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Avg win',
                  value: stats.avgWin(challenge) == null
                      ? 'N/A'
                      : '+\$${stats.avgWin(challenge)!.toStringAsFixed(2)}',
                  valueColor: stats.avgWin(challenge) == null ? null : palette.statusGood,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'Avg loss',
                  value: stats.avgLoss(challenge) == null
                      ? 'N/A'
                      : '\$${stats.avgLoss(challenge)!.toStringAsFixed(2)}',
                  valueColor: stats.avgLoss(challenge) == null ? null : palette.statusCritical,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(label: 'Total trades', value: '${stats.totalTrades(challenge)}'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionHeader(icon: Icons.psychology_rounded, label: 'Psychology & Emotion PnL'),
          const SizedBox(height: 8),
          EmotionAnalyticsCard(challenge: challenge),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(icon: Icons.receipt_long_rounded, label: 'Trades'),
              Text(
                '${sortedTrades.length} logged',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (sortedTrades.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No trades logged yet.',
                  style: TextStyle(color: palette.mutedInk),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final trade in sortedTrades)
                    TradeTile(trade: trade, onDelete: () => _confirmDeleteTrade(context, trade.id)),
                ],
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddTradeScreen(challenge: challenge)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Log trade'),
      ),
    );
  }
}
