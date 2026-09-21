import 'package:flutter_test/flutter_test.dart';

import 'package:task_game/models/challenge.dart';
import 'package:task_game/models/trade_entry.dart';
import 'package:task_game/utils/challenge_math.dart';

void main() {
  test('a trade logged for a future day still counts toward the actual balance line', () {
    final today = dateOnly(DateTime.now());
    final challenge = Challenge(
      id: 'c1',
      name: 'Test',
      startBalance: 10,
      targetBalance: 1000,
      durationDays: 20,
      startDate: today,
      trades: [
        TradeEntry(id: 't1', date: today, pnl: 5),
        // Dated one day ahead of "today" — the form allows this.
        TradeEntry(id: 't2', date: today.add(const Duration(days: 1)), pnl: 10),
      ],
    );

    // Wall-clock "today" is still day 0 for this challenge.
    expect(currentDayIndex(challenge), 0);
    // But a trade was logged for day 1, so the chart must reach that far.
    expect(lastActivityDayIndex(challenge), 1);
    expect(actualBalanceAtDayIndex(challenge, 1), 25);

    // The future-dated day itself must read as an activity day, not "future".
    expect(statusForDay(challenge, today.add(const Duration(days: 1))), DayStatus.profit);
  });
}
