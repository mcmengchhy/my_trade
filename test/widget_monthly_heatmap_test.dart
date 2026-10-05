import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_game/models/challenge.dart';
import 'package:task_game/models/trade_entry.dart';
import 'package:task_game/widgets/widget_monthly_heatmap.dart';

void main() {
  testWidgets('WidgetMonthlyHeatmap renders current month heatmap correctly', (tester) async {
    final now = DateTime(2026, 10, 5);
    final challenge = Challenge(
      id: 'c_test',
      name: '10K Challenge',
      startBalance: 10000,
      targetBalance: 12000,
      durationDays: 30,
      startDate: DateTime(2026, 10, 1),
      trades: [
        TradeEntry(
          id: 't1',
          date: DateTime(2026, 10, 1),
          instrument: 'EURUSD',
          direction: 'long',
          pnl: 150.0,
        ),
        TradeEntry(
          id: 't2',
          date: DateTime(2026, 10, 2),
          instrument: 'GBPUSD',
          direction: 'short',
          pnl: -50.0,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: WidgetMonthlyHeatmap(
              challenge: challenge,
              now: now,
            ),
          ),
        ),
      ),
    );

    expect(find.text('OCTOBER 2026'), findsOneWidget);
    expect(find.text('2/31 active'), findsOneWidget);
    expect(find.text('MONTH P&L'), findsOneWidget);
    expect(find.text('+\$100.00'), findsOneWidget);
    expect(find.text('1W'), findsOneWidget);
    expect(find.text('1L'), findsOneWidget);
  });
}
