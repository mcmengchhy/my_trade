import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/challenge_math.dart';

class ChallengeStatusVisual {
  const ChallengeStatusVisual(this.color, this.icon, this.label);

  final Color color;
  final IconData icon;
  final String label;
}

/// Fixed status→(color, icon, label) mapping shared by the dashboard card
/// and the detail screen, so "Achieved" always means the same green icon
/// wherever it appears.
ChallengeStatusVisual resolveStatusVisual(BuildContext context, ChallengeStatus status) {
  final palette = context.palette;
  switch (status) {
    case ChallengeStatus.achieved:
      return ChallengeStatusVisual(palette.statusGood, Icons.emoji_events_rounded, 'Achieved');
    case ChallengeStatus.failed:
      return ChallengeStatusVisual(palette.statusCritical, Icons.flag_rounded, 'Failed');
    case ChallengeStatus.active:
      return ChallengeStatusVisual(
        Theme.of(context).colorScheme.primary,
        Icons.trending_up_rounded,
        'Active',
      );
  }
}

/// Fixed pace→(color, icon, label) mapping — same shape as
/// [resolveStatusVisual], reused for "ahead of / on / behind pace".
ChallengeStatusVisual resolvePaceVisual(BuildContext context, PaceStatus pace) {
  final palette = context.palette;
  switch (pace) {
    case PaceStatus.ahead:
      return ChallengeStatusVisual(palette.statusGood, Icons.trending_up_rounded, 'Ahead of pace');
    case PaceStatus.onTrack:
      return ChallengeStatusVisual(
        Theme.of(context).colorScheme.primary,
        Icons.check_circle_rounded,
        'On track',
      );
    case PaceStatus.behind:
      return ChallengeStatusVisual(palette.statusCritical, Icons.trending_down_rounded, 'Behind pace');
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.visual});

  final ChallengeStatusVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: 13, color: visual.color),
          const SizedBox(width: 4),
          Text(
            visual.label,
            style: TextStyle(color: visual.color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
