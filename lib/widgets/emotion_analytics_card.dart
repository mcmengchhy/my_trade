import 'package:flutter/material.dart';

import '../models/challenge.dart';
import '../theme/app_palette.dart';
import '../utils/performance_stats.dart' as stats;

class EmotionAnalyticsCard extends StatelessWidget {
  const EmotionAnalyticsCard({super.key, required this.challenge});

  final Challenge challenge;

  IconData _emotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'calm':
        return Icons.self_improvement_rounded;
      case 'neutral':
        return Icons.sentiment_neutral_rounded;
      case 'fear':
        return Icons.sentiment_dissatisfied_rounded;
      case 'excited':
        return Icons.sentiment_very_satisfied_rounded;
      case 'angry':
        return Icons.mood_bad_rounded;
      case 'revenge':
        return Icons.bolt_rounded;
      case 'fomo':
        return Icons.timer_outlined;
      default:
        return Icons.psychology_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final emotionMap = stats.emotionStats(challenge);
    final violations = stats.planViolations(challenge);
    final violationPnl = violations.fold<double>(0, (sum, t) => sum + t.pnl);

    if (emotionMap.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Log trades with emotion tags to see psychological insights.',
              style: TextStyle(color: palette.mutedInk, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final sortedEmotions = emotionMap.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final stat in sortedEmotions) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: stat.netPnl >= 0
                            ? palette.statusGood.withValues(alpha: 0.12)
                            : palette.statusCritical.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _emotionIcon(stat.emotion),
                        size: 16,
                        color: stat.netPnl >= 0 ? palette.statusGood : palette.statusCritical,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stat.emotion,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            '${stat.count} trade${stat.count == 1 ? '' : 's'} · ${stat.winRate.toStringAsFixed(0)}% Win Rate',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: palette.mutedInk,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${stat.netPnl >= 0 ? '+\$' : '-\$'}${stat.netPnl.abs().toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: stat.netPnl >= 0 ? palette.statusGood : palette.statusCritical,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            if (violations.isNotEmpty) ...[
              const Divider(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.statusCritical.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: palette.statusCritical),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${violations.length} trade${violations.length == 1 ? '' : 's'} broke plan (${violationPnl >= 0 ? '+\$' : '-\$'}${violationPnl.abs().toStringAsFixed(2)})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.statusCritical,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
