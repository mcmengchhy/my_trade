import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_game/models/challenge.dart';
import 'package:task_game/models/trade_entry.dart';
import 'package:task_game/theme/app_theme.dart';
import 'package:task_game/utils/performance_stats.dart' as stats;
import 'package:task_game/widgets/emotion_analytics_card.dart';

void main() {
  group('Emotion Analytics Tests', () {
    final challenge = Challenge(
      id: 'c1',
      name: 'Emotion Test Challenge',
      startBalance: 100,
      targetBalance: 500,
      durationDays: 20,
      startDate: DateTime.now(),
      trades: [
        TradeEntry(
          id: 't1',
          date: DateTime.now(),
          pnl: 10.0,
          emotion: 'Calm',
          followedPlan: true,
        ),
        TradeEntry(
          id: 't2',
          date: DateTime.now(),
          pnl: 15.0,
          emotion: 'Calm',
          followedPlan: true,
        ),
        TradeEntry(
          id: 't3',
          date: DateTime.now(),
          pnl: -5.0,
          emotion: 'FOMO',
          followedPlan: false,
        ),
        TradeEntry(
          id: 't4',
          date: DateTime.now(),
          pnl: -10.0,
          emotion: 'Revenge',
          followedPlan: false,
        ),
      ],
    );

    test('emotionStats aggregates trade count and PnL correctly', () {
      final resultMap = stats.emotionStats(challenge);
      expect(resultMap.length, 3);

      final calmStat = resultMap['Calm'];
      expect(calmStat, isNotNull);
      expect(calmStat!.count, 2);
      expect(calmStat.netPnl, 25.0);
      expect(calmStat.winRate, 100.0);

      final fomoStat = resultMap['FOMO'];
      expect(fomoStat, isNotNull);
      expect(fomoStat!.count, 1);
      expect(fomoStat.netPnl, -5.0);

      final violations = stats.planViolations(challenge);
      expect(violations.length, 2);
    });

    testWidgets('EmotionAnalyticsCard renders emotion items and violation warning banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: EmotionAnalyticsCard(challenge: challenge),
          ),
        ),
      );

      expect(find.text('Calm'), findsOneWidget);
      expect(find.text('FOMO'), findsOneWidget);
      expect(find.text('Revenge'), findsOneWidget);
      expect(find.text('+\$25.00'), findsOneWidget);
      expect(find.text('-\$5.00'), findsOneWidget);
      expect(find.text('-\$10.00'), findsOneWidget);
      expect(find.textContaining('2 trades broke plan'), findsOneWidget);
    });
  });
}
