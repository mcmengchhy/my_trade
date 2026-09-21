class TradeEntry {
  final String id;
  final DateTime date;
  final double pnl;
  final String? instrument;
  final String? direction; // 'long' | 'short' | null
  final double? entryPrice;
  final double? exitPrice;
  final double? size;
  final String? note;

  /// Setup type, e.g. "Breakout", "Pullback", "Reversal" — free string from
  /// a preset list, same pattern as [direction].
  final String? setup;
  final double? stopLoss;
  final double? takeProfit;

  /// Emotion at time of trade, e.g. "Calm", "FOMO", "Revenge".
  final String? emotion;

  /// Whether the trader followed their own plan/rules. Null = not answered.
  final bool? followedPlan;

  /// Reflection: "what did you learn?"
  final String? lesson;

  TradeEntry({
    required this.id,
    required this.date,
    required this.pnl,
    this.instrument,
    this.direction,
    this.entryPrice,
    this.exitPrice,
    this.size,
    this.note,
    this.setup,
    this.stopLoss,
    this.takeProfit,
    this.emotion,
    this.followedPlan,
    this.lesson,
  });

  TradeEntry copyWith({
    DateTime? date,
    double? pnl,
    String? instrument,
    String? direction,
    double? entryPrice,
    double? exitPrice,
    double? size,
    String? note,
    String? setup,
    double? stopLoss,
    double? takeProfit,
    String? emotion,
    bool? followedPlan,
    String? lesson,
  }) {
    return TradeEntry(
      id: id,
      date: date ?? this.date,
      pnl: pnl ?? this.pnl,
      instrument: instrument ?? this.instrument,
      direction: direction ?? this.direction,
      entryPrice: entryPrice ?? this.entryPrice,
      exitPrice: exitPrice ?? this.exitPrice,
      size: size ?? this.size,
      note: note ?? this.note,
      setup: setup ?? this.setup,
      stopLoss: stopLoss ?? this.stopLoss,
      takeProfit: takeProfit ?? this.takeProfit,
      emotion: emotion ?? this.emotion,
      followedPlan: followedPlan ?? this.followedPlan,
      lesson: lesson ?? this.lesson,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'pnl': pnl,
        'instrument': instrument,
        'direction': direction,
        'entryPrice': entryPrice,
        'exitPrice': exitPrice,
        'size': size,
        'note': note,
        'setup': setup,
        'stopLoss': stopLoss,
        'takeProfit': takeProfit,
        'emotion': emotion,
        'followedPlan': followedPlan,
        'lesson': lesson,
      };

  factory TradeEntry.fromJson(Map<String, dynamic> json) => TradeEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        pnl: (json['pnl'] as num).toDouble(),
        instrument: json['instrument'] as String?,
        direction: json['direction'] as String?,
        entryPrice: (json['entryPrice'] as num?)?.toDouble(),
        exitPrice: (json['exitPrice'] as num?)?.toDouble(),
        size: (json['size'] as num?)?.toDouble(),
        note: json['note'] as String?,
        setup: json['setup'] as String?,
        stopLoss: (json['stopLoss'] as num?)?.toDouble(),
        takeProfit: (json['takeProfit'] as num?)?.toDouble(),
        emotion: json['emotion'] as String?,
        followedPlan: json['followedPlan'] as bool?,
        lesson: json['lesson'] as String?,
      );
}
