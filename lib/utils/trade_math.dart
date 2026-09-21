import '../models/trade_entry.dart';

/// Dollar risk on a single trade, derived (never stored) from entry/stop
/// loss/size — only defined when all three are present.
double? riskAmount(TradeEntry t) {
  final entry = t.entryPrice;
  final stop = t.stopLoss;
  final size = t.size;
  if (entry == null || stop == null || size == null) return null;
  return (entry - stop).abs() * size;
}

/// Reward:risk ratio, derived from entry/stop loss/take profit — only
/// defined when all three are present and the stop isn't at entry.
double? riskRewardRatio(TradeEntry t) {
  final entry = t.entryPrice;
  final stop = t.stopLoss;
  final target = t.takeProfit;
  if (entry == null || stop == null || target == null) return null;
  final risk = (entry - stop).abs();
  if (risk == 0) return null;
  return (target - entry).abs() / risk;
}
