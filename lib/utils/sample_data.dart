import '../models/trade_entry.dart';

/// Generates a list of 14 realistic sample trades with varying dates, PnLs,
/// setups, emotions, and lessons sequentially starting from [startDate].
List<TradeEntry> generateSampleTrades(DateTime startDate) {
  final baseDate = DateTime(startDate.year, startDate.month, startDate.day);

  final sampleRaw = [
    (0, 2.50, 'EUR/USD', 'long', 'Breakout', 1.0820, 1.0845, 0.5, 'Calm', true, 'Clean breakout entry above key resistance'),
    (1, 3.20, 'GBP/USD', 'long', 'Pullback', 1.2650, 1.2682, 0.4, 'Calm', true, 'Patience paid off waiting for pullback retest'),
    (2, -1.50, 'BTC/USD', 'short', 'Reversal', 64500.0, 64650.0, 0.05, 'Neutral', true, 'Stop loss respected after price reversed'),
    (3, 4.10, 'XAU/USD', 'long', 'Trend continuation', 2320.0, 2328.2, 0.2, 'Calm', true, 'Rode gold momentum up to daily target'),
    (4, -2.00, 'EUR/USD', 'short', 'Breakout', 1.0810, 1.0830, 0.5, 'FOMO', false, 'Chased entry after candle closed too far'),
    (5, 5.00, 'GBP/USD', 'long', 'Pullback', 1.2680, 1.2730, 0.5, 'Calm', true, 'Held position through minor pullback to TP'),
    (6, 6.20, 'SPY', 'long', 'Trend continuation', 520.0, 526.2, 1.0, 'Calm', true, 'Strong market trend following daily plan'),
    (7, -2.50, 'AAPL', 'short', 'Reversal', 185.0, 187.5, 2.0, 'Revenge', false, 'Should not have re-entered after initial stop'),
    (8, 7.50, 'EUR/USD', 'long', 'Breakout', 1.0840, 1.0915, 0.6, 'Calm', true, 'Great R:R ratio trade with clean structure'),
    (9, 8.10, 'XAU/USD', 'long', 'Pullback', 2330.0, 2346.2, 0.2, 'Calm', true, 'Executed plan smoothly with proper risk'),
    (10, 10.00, 'BTC/USD', 'long', 'Trend continuation', 65000.0, 66000.0, 0.05, 'Excited', true, 'High conviction trade reached target level'),
    (11, -3.00, 'GBP/USD', 'short', 'Breakout', 1.2720, 1.2750, 0.5, 'Neutral', true, 'False breakout, tight stop saved account'),
    (12, 12.50, 'EUR/USD', 'long', 'Pullback', 1.0900, 1.1025, 0.6, 'Calm', true, 'Perfect retest entry at key daily support'),
    (13, 15.00, 'XAU/USD', 'long', 'Trend continuation', 2345.0, 2375.0, 0.2, 'Calm', true, 'Compounding growth momentum working great'),
  ];

  return List.generate(sampleRaw.length, (index) {
    final data = sampleRaw[index];
    final dayOffset = data.$1;
    final tradeDate = baseDate.add(Duration(days: dayOffset));
    return TradeEntry(
      id: 'sample_${index}_${DateTime.now().microsecondsSinceEpoch + index}',
      date: tradeDate,
      pnl: data.$2,
      instrument: data.$3,
      direction: data.$4,
      entryPrice: data.$6,
      exitPrice: data.$7,
      size: data.$8,
      setup: data.$5,
      emotion: data.$9,
      followedPlan: data.$10,
      lesson: data.$11,
    );
  });
}
