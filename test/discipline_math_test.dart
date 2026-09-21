import 'package:flutter_test/flutter_test.dart';

import 'package:task_game/models/challenge.dart';
import 'package:task_game/models/trade_entry.dart';
import 'package:task_game/utils/challenge_math.dart';

Challenge _challenge({
  required DateTime startDate,
  List<TradeEntry> trades = const [],
  double? maxDailyLossPct,
}) {
  return Challenge(
    id: 'c1',
    name: 'Test',
    startBalance: 100,
    targetBalance: 200,
    durationDays: 10,
    startDate: startDate,
    trades: trades,
    maxDailyLossPct: maxDailyLossPct,
  );
}

void main() {
  final today = dateOnly(DateTime.now());

  group('todaysRequiredProfit', () {
    test('is zero on day 0 (expected balance == start balance)', () {
      final c = _challenge(startDate: today);
      expect(todaysRequiredProfit(c), closeTo(0, 1e-9));
    });

    test('matches the gap between yesterday and today\'s expected balance', () {
      final c = _challenge(startDate: today.subtract(const Duration(days: 3)));
      final idx = currentDayIndex(c);
      expect(idx, 3);
      final expectedGap = expectedBalance(c, idx) - expectedBalance(c, idx - 1);
      expect(todaysRequiredProfit(c), closeTo(expectedGap, 1e-9));
    });
  });

  group('paceStatus', () {
    test('on track when balance matches the expected pace exactly', () {
      final c = _challenge(startDate: today);
      expect(paceStatus(c), PaceStatus.onTrack);
    });

    test('ahead when balance is well above the expected pace', () {
      final c = _challenge(
        startDate: today,
        trades: [TradeEntry(id: 't1', date: today, pnl: 10)],
      );
      expect(paceStatus(c), PaceStatus.ahead);
    });

    test('behind when balance is well below the expected pace', () {
      final c = _challenge(
        startDate: today,
        trades: [TradeEntry(id: 't1', date: today, pnl: -10)],
      );
      expect(paceStatus(c), PaceStatus.behind);
    });
  });

  group('planAdherence', () {
    test('null when no trade has answered "followed plan?"', () {
      final c = _challenge(
        startDate: today,
        trades: [TradeEntry(id: 't1', date: today, pnl: 5)],
      );
      expect(planAdherence(c), isNull);
    });

    test('percentage counts only answered trades', () {
      final c = _challenge(
        startDate: today,
        trades: [
          TradeEntry(id: 't1', date: today, pnl: 5, followedPlan: true),
          TradeEntry(id: 't2', date: today, pnl: -5, followedPlan: false),
          TradeEntry(id: 't3', date: today, pnl: 5, followedPlan: true),
          TradeEntry(id: 't4', date: today, pnl: 5), // not answered — excluded
        ],
      );
      expect(planAdherence(c), closeTo(2 / 3 * 100, 1e-9));
    });
  });

  group('dailyLossBreached', () {
    test('null when no limit is set', () {
      final c = _challenge(
        startDate: today,
        trades: [TradeEntry(id: 't1', date: today, pnl: -50)],
      );
      expect(dailyLossBreached(c, today), isNull);
    });

    test('true when a day\'s net loss exceeds the limit', () {
      final c = _challenge(
        startDate: today,
        maxDailyLossPct: 0.02, // 2% of 100 = $2
        trades: [TradeEntry(id: 't1', date: today, pnl: -3)],
      );
      expect(dailyLossBreached(c, today), isTrue);
    });

    test('false when within the limit', () {
      final c = _challenge(
        startDate: today,
        maxDailyLossPct: 0.02,
        trades: [TradeEntry(id: 't1', date: today, pnl: -1)],
      );
      expect(dailyLossBreached(c, today), isFalse);
    });
  });

  group('currentProfitStreak', () {
    test('stops at the most recent non-profit day', () {
      final c = _challenge(
        startDate: today.subtract(const Duration(days: 3)),
        trades: [
          TradeEntry(id: 't0', date: today.subtract(const Duration(days: 3)), pnl: 5),
          TradeEntry(id: 't1', date: today.subtract(const Duration(days: 2)), pnl: 5),
          TradeEntry(id: 't2', date: today.subtract(const Duration(days: 1)), pnl: -5),
          TradeEntry(id: 't3', date: today, pnl: 5),
        ],
      );
      expect(currentProfitStreak(c), 1);
    });

    test('counts every day back to the start when all are profitable', () {
      final c = _challenge(
        startDate: today.subtract(const Duration(days: 2)),
        trades: [
          TradeEntry(id: 't0', date: today.subtract(const Duration(days: 2)), pnl: 5),
          TradeEntry(id: 't1', date: today.subtract(const Duration(days: 1)), pnl: 5),
          TradeEntry(id: 't2', date: today, pnl: 5),
        ],
      );
      expect(currentProfitStreak(c), 3);
    });
  });
}
