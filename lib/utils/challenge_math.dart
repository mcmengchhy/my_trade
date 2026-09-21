import 'dart:math' as math;

import '../models/challenge.dart';

enum ChallengeStatus { active, achieved, failed }

enum DayStatus { future, noActivity, profit, loss, breakeven }

enum PaceStatus { ahead, onTrack, behind }

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The constant daily growth rate required to go from [startBalance] to
/// [targetBalance] in [durationDays] days, compounding once per day.
double requiredDailyRate(double startBalance, double targetBalance, int durationDays) {
  if (startBalance <= 0 || durationDays <= 0) return 0;
  return math.pow(targetBalance / startBalance, 1 / durationDays) - 1;
}

/// Expected balance on day [dayIndex] (0 = start date) if the challenge is
/// exactly on pace.
double expectedBalance(Challenge c, int dayIndex) {
  final rate = requiredDailyRate(c.startBalance, c.targetBalance, c.durationDays);
  final clampedDay = dayIndex.clamp(0, c.durationDays);
  return c.startBalance * math.pow(1 + rate, clampedDay);
}

/// 0-based index of "today" relative to the challenge start date, clamped to
/// the challenge's duration.
int currentDayIndex(Challenge c, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final diff = today.difference(dateOnly(c.startDate)).inDays;
  return diff.clamp(0, c.durationDays - 1);
}

ChallengeStatus challengeStatus(Challenge c, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  if (c.currentBalance >= c.targetBalance) return ChallengeStatus.achieved;
  final daysElapsed = today.difference(dateOnly(c.startDate)).inDays;
  if (daysElapsed >= c.durationDays) return ChallengeStatus.failed;
  return ChallengeStatus.active;
}

double progressFraction(Challenge c) {
  final span = c.targetBalance - c.startBalance;
  if (span <= 0) return 1;
  return ((c.currentBalance - c.startBalance) / span).clamp(0, 1);
}

/// 0-based index of the furthest day that has any logged trade, clamped to
/// the challenge's duration. Trades can be logged for any day within the
/// challenge window, including ones after today, so charts/heatmaps need
/// this rather than [currentDayIndex] alone to avoid hiding logged data.
int lastActivityDayIndex(Challenge c) {
  if (c.trades.isEmpty) return 0;
  final start = dateOnly(c.startDate);
  final maxDate = c.trades
      .map((t) => dateOnly(t.date))
      .reduce((a, b) => a.isAfter(b) ? a : b);
  return maxDate.difference(start).inDays.clamp(0, c.durationDays - 1);
}

/// Cumulative balance as of the end of day [dayIndex] (0 = start date),
/// based on trades booked on or before that date.
double actualBalanceAtDayIndex(Challenge c, int dayIndex) {
  final cutoff = dateOnly(c.startDate).add(Duration(days: dayIndex));
  final pnl = c.trades
      .where((t) => !dateOnly(t.date).isAfter(cutoff))
      .fold(0.0, (sum, t) => sum + t.pnl);
  return c.startBalance + pnl;
}

/// Net P/L booked on a given calendar day.
double netPnlForDay(Challenge c, DateTime day) {
  final target = dateOnly(day);
  return c.trades
      .where((t) => dateOnly(t.date) == target)
      .fold(0.0, (sum, t) => sum + t.pnl);
}

bool hasTradesOnDay(Challenge c, DateTime day) {
  final target = dateOnly(day);
  return c.trades.any((t) => dateOnly(t.date) == target);
}

DayStatus statusForDay(Challenge c, DateTime day) {
  final target = dateOnly(day);
  // A day with logged trades is never "future", even if it's dated ahead of
  // today (the challenge form allows planning/logging any day in range).
  if (hasTradesOnDay(c, target)) {
    final pnl = netPnlForDay(c, target);
    if (pnl > 0) return DayStatus.profit;
    if (pnl < 0) return DayStatus.loss;
    return DayStatus.breakeven;
  }
  final today = dateOnly(DateTime.now());
  if (target.isAfter(today)) return DayStatus.future;
  return DayStatus.noActivity;
}

/// The profit needed today to stay exactly on the required compounding
/// pace: the gap between yesterday's and today's expected balance.
double todaysRequiredProfit(Challenge c, {DateTime? now}) {
  final idx = currentDayIndex(c, now: now);
  final previousExpected = idx == 0 ? c.startBalance : expectedBalance(c, idx - 1);
  return expectedBalance(c, idx) - previousExpected;
}

/// Compares actual balance to the expected (on-pace) balance for today,
/// with a small tolerance band so tiny gaps don't read as "behind".
PaceStatus paceStatus(Challenge c, {DateTime? now}) {
  final idx = currentDayIndex(c, now: now);
  final expected = expectedBalance(c, idx);
  final tolerance = expected.abs() * 0.02;
  final diff = c.currentBalance - expected;
  if (diff > tolerance) return PaceStatus.ahead;
  if (diff < -tolerance) return PaceStatus.behind;
  return PaceStatus.onTrack;
}

/// Number of trades logged today.
int tradesToday(Challenge c, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  return c.trades.where((t) => dateOnly(t.date) == today).length;
}

/// Trading days left in the challenge after today (never negative).
int remainingDays(Challenge c, {DateTime? now}) {
  return (c.durationDays - currentDayIndex(c, now: now) - 1).clamp(0, c.durationDays);
}

/// Consecutive profit days walking backward from the most recent day that
/// has any logged activity. 0 if that day wasn't a profit day (or there's
/// no activity at all).
int currentProfitStreak(Challenge c) {
  final lastDay = lastActivityDayIndex(c);
  var streak = 0;
  for (var i = lastDay; i >= 0; i--) {
    final date = dateOnly(c.startDate).add(Duration(days: i));
    if (!hasTradesOnDay(c, date)) break;
    if (netPnlForDay(c, date) <= 0) break;
    streak++;
  }
  return streak;
}

/// % of trades where the trader answered "yes" to following their plan, out
/// of the trades where they answered at all. Null if none have been
/// answered yet (not "0%" — there's simply no data).
double? planAdherence(Challenge c) {
  final answered = c.trades.where((t) => t.followedPlan != null).toList();
  if (answered.isEmpty) return null;
  final followed = answered.where((t) => t.followedPlan == true).length;
  return followed / answered.length * 100;
}

/// Whether the challenge's daily loss limit was breached on [day]. Null if
/// no limit is set for this challenge.
bool? dailyLossBreached(Challenge c, DateTime day) {
  final limitPct = c.maxDailyLossPct;
  if (limitPct == null) return null;
  final limit = -limitPct.abs() * c.startBalance;
  return netPnlForDay(c, day) < limit;
}
