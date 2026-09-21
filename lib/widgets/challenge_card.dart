import 'package:flutter/material.dart';

import '../models/challenge.dart';
import '../theme/app_palette.dart';
import '../utils/challenge_math.dart';
import 'status_chip.dart';

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key, required this.challenge, this.onTap});

  final Challenge challenge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final status = challengeStatus(challenge);
    final progress = progressFraction(challenge);
    final dayIndex = currentDayIndex(challenge);
    final daysLeft = challenge.durationDays - dayIndex - 1;

    final visual = resolveStatusVisual(context, status);
    final statusColor = visual.color;
    final requiredToday = todaysRequiredProfit(challenge);
    final actualToday = netPnlForDay(challenge, DateTime.now());
    final paceVisual = resolvePaceVisual(context, paceStatus(challenge));

    final delta = challenge.currentBalance - challenge.startBalance;
    final deltaPct = challenge.startBalance > 0 ? delta / challenge.startBalance * 100 : 0.0;
    final deltaColor = delta > 0
        ? palette.statusGood
        : (delta < 0 ? palette.statusCritical : palette.mutedInk);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      challenge.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(visual: visual),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                status == ChallengeStatus.active
                    ? 'Day ${dayIndex + 1} of ${challenge.durationDays} · $daysLeft days left'
                    : 'Day ${dayIndex + 1} of ${challenge.durationDays}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Color.lerp(scheme.surface, statusColor, 0.18),
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '\$${challenge.currentBalance.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        delta > 0
                            ? Icons.arrow_upward_rounded
                            : (delta < 0 ? Icons.arrow_downward_rounded : Icons.remove_rounded),
                        size: 14,
                        color: deltaColor,
                      ),
                      Text(
                        '${deltaPct.abs().toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: deltaColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  Text(
                    'Target \$${challenge.targetBalance.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                  ),
                ],
              ),
              if (status == ChallengeStatus.active) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Required today \$${requiredToday.toStringAsFixed(2)} · '
                        'Today ${actualToday >= 0 ? '+' : ''}\$${actualToday.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(paceVisual.icon, size: 14, color: paceVisual.color),
                    const SizedBox(width: 3),
                    Text(
                      paceVisual.label,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: paceVisual.color),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
