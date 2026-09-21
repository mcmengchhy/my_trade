import 'package:flutter_test/flutter_test.dart';

import 'package:task_game/models/challenge.dart';
import 'package:task_game/models/trade_entry.dart';
import 'package:task_game/utils/performance_stats.dart';

void main() {
  final startDate = DateTime(2026, 1, 1);

  Challenge challengeWith(List<TradeEntry> trades) => Challenge(
        id: 'c1',
        name: 'Test',
        startBalance: 100,
        targetBalance: 200,
        durationDays: 10,
        startDate: startDate,
        trades: trades,
      );

  test('all stats are null/zero on a challenge with no trades', () {
    final c = challengeWith([]);
    expect(totalTrades(c), 0);
    expect(winRate(c), isNull);
    expect(profitFactor(c), isNull);
    expect(avgWin(c), isNull);
    expect(avgLoss(c), isNull);
    expect(bestTrade(c), isNull);
    expect(worstTrade(c), isNull);
  });

  test('computes win rate, profit factor, and averages from a mixed set of trades', () {
    // 2 wins (+10, +30), 2 losses (-10, -20) -> gross profit 40, gross loss 30.
    final c = challengeWith([
      TradeEntry(id: 't1', date: startDate, pnl: 10),
      TradeEntry(id: 't2', date: startDate, pnl: -10),
      TradeEntry(id: 't3', date: startDate, pnl: 30),
      TradeEntry(id: 't4', date: startDate, pnl: -20),
    ]);

    expect(totalTrades(c), 4);
    expect(winRate(c), closeTo(50, 1e-9));
    expect(profitFactor(c), closeTo(40 / 30, 1e-9));
    expect(avgWin(c), closeTo(20, 1e-9));
    expect(avgLoss(c), closeTo(-15, 1e-9));
    expect(bestTrade(c)!.pnl, 30);
    expect(worstTrade(c)!.pnl, -20);
  });

  test('profit factor is null when there are no losing trades yet', () {
    final c = challengeWith([TradeEntry(id: 't1', date: startDate, pnl: 10)]);
    expect(profitFactor(c), isNull);
  });
}
