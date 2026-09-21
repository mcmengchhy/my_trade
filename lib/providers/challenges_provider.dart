import 'package:flutter/foundation.dart';

import '../models/challenge.dart';
import '../models/trade_entry.dart';
import '../services/home_widget_service.dart';
import '../services/storage_service.dart';
import '../utils/challenge_math.dart';

class ChallengesProvider extends ChangeNotifier {
  ChallengesProvider({StorageService? storage})
      : _storage = storage ?? StorageService();

  final StorageService _storage;
  List<Challenge> _challenges = [];
  bool _loaded = false;
  bool _isWidgetEnabled = true;
  String? _selectedWidgetChallengeId;

  List<Challenge> get challenges => List.unmodifiable(_challenges);
  bool get isLoaded => _loaded;
  bool get isWidgetEnabled => _isWidgetEnabled;
  String? get selectedWidgetChallengeId => _selectedWidgetChallengeId;

  Future<void> load() async {
    _challenges = await _storage.loadChallenges();
    _isWidgetEnabled = await _storage.loadWidgetEnabled();
    _selectedWidgetChallengeId = await _storage.loadSelectedWidgetChallengeId();
    _loaded = true;
    notifyListeners();
    _syncHomeWidget().catchError((_) {});
  }

  Future<void> setWidgetEnabled(bool enabled) async {
    _isWidgetEnabled = enabled;
    notifyListeners();
    await _storage.saveWidgetEnabled(enabled);
    await _syncHomeWidget();
  }

  Future<void> setSelectedWidgetChallengeId(String? id) async {
    _selectedWidgetChallengeId = id;
    notifyListeners();
    await _storage.saveSelectedWidgetChallengeId(id);
    await _syncHomeWidget();
  }

  Future<void> _persist() async {
    await _storage.saveChallenges(_challenges);
    await _syncHomeWidget();
  }

  Future<void> _syncHomeWidget() async {
    try {
      if (!_isWidgetEnabled) {
        await HomeWidgetService.syncData(activeChallenge: null, enabled: false);
        return;
      }

      Challenge? target;
      if (_selectedWidgetChallengeId != null) {
        target = _challenges.where((c) => c.id == _selectedWidgetChallengeId).firstOrNull;
      }

      if (target == null) {
        final activeList = _challenges.where((c) => challengeStatus(c) == ChallengeStatus.active).toList();
        target = activeList.isNotEmpty ? activeList.first : (_challenges.isNotEmpty ? _challenges.first : null);
      }

      await HomeWidgetService.syncData(activeChallenge: target, enabled: true);
    } catch (_) {}
  }

  Challenge byId(String id) => _challenges.firstWhere((c) => c.id == id);

  Future<void> addChallenge({
    required String name,
    required double startBalance,
    required double targetBalance,
    required int durationDays,
    required DateTime startDate,
    List<String> rules = const [],
    double? maxDailyLossPct,
    List<TradeEntry>? trades,
  }) async {
    final challenge = Challenge(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      startBalance: startBalance,
      targetBalance: targetBalance,
      durationDays: durationDays,
      startDate: startDate,
      rules: rules,
      maxDailyLossPct: maxDailyLossPct,
      trades: trades ?? [],
    );
    _challenges = [..._challenges, challenge];
    notifyListeners();
    await _persist();
  }

  Future<void> deleteChallenge(String id) async {
    _challenges = _challenges.where((c) => c.id != id).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> addTrade(String challengeId, TradeEntry trade) async {
    _challenges = _challenges.map((c) {
      if (c.id != challengeId) return c;
      return c.copyWith(trades: [...c.trades, trade]);
    }).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> deleteTrade(String challengeId, String tradeId) async {
    _challenges = _challenges.map((c) {
      if (c.id != challengeId) return c;
      return c.copyWith(
        trades: c.trades.where((t) => t.id != tradeId).toList(),
      );
    }).toList();
    notifyListeners();
    await _persist();
  }
}
