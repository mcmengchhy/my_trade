import '../models/challenge.dart';
import '../models/trade_entry.dart';

int totalTrades(Challenge c) => c.trades.length;

/// % of trades that were profitable. Null if there are no trades yet.
double? winRate(Challenge c) {
  if (c.trades.isEmpty) return null;
  final wins = c.trades.where((t) => t.pnl > 0).length;
  return wins / c.trades.length * 100;
}

/// Gross profit / gross loss. Null if there are no losing trades to divide
/// by (including "no trades at all").
double? profitFactor(Challenge c) {
  final grossProfit = c.trades.where((t) => t.pnl > 0).fold(0.0, (s, t) => s + t.pnl);
  final grossLoss = c.trades.where((t) => t.pnl < 0).fold(0.0, (s, t) => s + t.pnl).abs();
  if (grossLoss == 0) return null;
  return grossProfit / grossLoss;
}

double? avgWin(Challenge c) {
  final wins = c.trades.where((t) => t.pnl > 0).toList();
  if (wins.isEmpty) return null;
  return wins.fold(0.0, (s, t) => s + t.pnl) / wins.length;
}

double? avgLoss(Challenge c) {
  final losses = c.trades.where((t) => t.pnl < 0).toList();
  if (losses.isEmpty) return null;
  return losses.fold(0.0, (s, t) => s + t.pnl) / losses.length;
}

TradeEntry? bestTrade(Challenge c) {
  if (c.trades.isEmpty) return null;
  return c.trades.reduce((a, b) => b.pnl > a.pnl ? b : a);
}

TradeEntry? worstTrade(Challenge c) {
  if (c.trades.isEmpty) return null;
  return c.trades.reduce((a, b) => b.pnl < a.pnl ? b : a);
}

class EmotionStat {
  final String emotion;
  final double netPnl;
  final int count;
  final int winCount;

  const EmotionStat({
    required this.emotion,
    required this.netPnl,
    required this.count,
    required this.winCount,
  });

  double get winRate => count == 0 ? 0.0 : (winCount / count) * 100;
}

/// Returns a map of emotion name to [EmotionStat] for all trades in [c].
Map<String, EmotionStat> emotionStats(Challenge c) {
  final result = <String, EmotionStat>{};
  for (final trade in c.trades) {
    final emotion = trade.emotion ?? 'Unspecified';
    final existing = result[emotion];
    final netPnl = (existing?.netPnl ?? 0.0) + trade.pnl;
    final count = (existing?.count ?? 0) + 1;
    final winCount = (existing?.winCount ?? 0) + (trade.pnl > 0 ? 1 : 0);
    result[emotion] = EmotionStat(
      emotion: emotion,
      netPnl: netPnl,
      count: count,
      winCount: winCount,
    );
  }
  return result;
}

/// Returns total trades where plan was NOT followed (`followedPlan == false`).
List<TradeEntry> planViolations(Challenge c) {
  return c.trades.where((t) => t.followedPlan == false).toList();
}
