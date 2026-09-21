import 'trade_entry.dart';

class Challenge {
  final String id;
  final String name;
  final double startBalance;
  final double targetBalance;
  final int durationDays;
  final DateTime startDate;
  final List<TradeEntry> trades;

  /// Trading rules the trader defined for this challenge (free text, e.g.
  /// "Risk max 1% per trade"). Purely informational/display for now.
  final List<String> rules;

  /// Max daily loss as a fraction of [startBalance] (e.g. 0.02 = 2%).
  /// Null means no limit set.
  final double? maxDailyLossPct;

  Challenge({
    required this.id,
    required this.name,
    required this.startBalance,
    required this.targetBalance,
    required this.durationDays,
    required this.startDate,
    List<TradeEntry>? trades,
    List<String>? rules,
    this.maxDailyLossPct,
  })  : trades = trades ?? [],
        rules = rules ?? [];

  DateTime get endDate => startDate.add(Duration(days: durationDays - 1));

  double get currentBalance =>
      startBalance + trades.fold(0.0, (sum, t) => sum + t.pnl);

  Challenge copyWith({
    String? name,
    double? startBalance,
    double? targetBalance,
    int? durationDays,
    DateTime? startDate,
    List<TradeEntry>? trades,
    List<String>? rules,
    double? maxDailyLossPct,
  }) {
    return Challenge(
      id: id,
      name: name ?? this.name,
      startBalance: startBalance ?? this.startBalance,
      targetBalance: targetBalance ?? this.targetBalance,
      durationDays: durationDays ?? this.durationDays,
      startDate: startDate ?? this.startDate,
      trades: trades ?? this.trades,
      rules: rules ?? this.rules,
      maxDailyLossPct: maxDailyLossPct ?? this.maxDailyLossPct,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startBalance': startBalance,
        'targetBalance': targetBalance,
        'durationDays': durationDays,
        'startDate': startDate.toIso8601String(),
        'trades': trades.map((t) => t.toJson()).toList(),
        'rules': rules,
        'maxDailyLossPct': maxDailyLossPct,
      };

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: json['id'] as String,
        name: json['name'] as String,
        startBalance: (json['startBalance'] as num).toDouble(),
        targetBalance: (json['targetBalance'] as num).toDouble(),
        durationDays: json['durationDays'] as int,
        startDate: DateTime.parse(json['startDate'] as String),
        trades: (json['trades'] as List<dynamic>? ?? [])
            .map((t) => TradeEntry.fromJson(t as Map<String, dynamic>))
            .toList(),
        rules: (json['rules'] as List<dynamic>? ?? []).cast<String>(),
        maxDailyLossPct: (json['maxDailyLossPct'] as num?)?.toDouble(),
      );
}
