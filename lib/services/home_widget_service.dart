import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../models/challenge.dart';
import '../models/user_profile.dart';
import '../utils/challenge_math.dart';

class HomeWidgetService {
  static const String _iOSWidgetName = 'TradeChallengeWidget';
  static const String _androidWidgetName = 'TradeChallengeWidgetProvider';

  static bool get _isTest {
    final binding = ServicesBinding.instance.runtimeType.toString();
    return binding.contains('TestWidgetsFlutterBinding');
  }

  static Future<void> _safeSave(String key, String value) async {
    try {
      await HomeWidget.saveWidgetData<String>(key, value)
          .timeout(const Duration(milliseconds: 100), onTimeout: () => null);
    } catch (_) {}
  }

  static Future<void> _safeUpdate() async {
    try {
      await HomeWidget.updateWidget(
        name: _iOSWidgetName,
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      ).timeout(const Duration(milliseconds: 100), onTimeout: () => null);
    } catch (_) {}
  }

  /// Syncs active challenge balance, required daily profit, pace status, and
  /// trader level data to native iOS and Android Home Screen Widgets.
  static Future<void> syncData({
    Challenge? activeChallenge,
    UserProfile? profile,
    bool enabled = true,
  }) async {
    if (_isTest) return;
    try {
      if (!enabled) {
        await _safeSave('challenge_name', 'Widget Disabled');
        await _safeSave('current_balance', '\$0.00');
        await _safeSave('target_balance', '\$0');
        await _safeSave('pace_status', 'Off');
        await _safeSave('required_today', 'Enable in settings');
      } else if (activeChallenge != null) {
        final pace = paceStatus(activeChallenge);
        final paceLabel = pace == PaceStatus.ahead
            ? 'Ahead'
            : (pace == PaceStatus.behind ? 'Behind' : 'On Track');
        final reqToday = todaysRequiredProfit(activeChallenge);

        await _safeSave('challenge_name', activeChallenge.name);
        await _safeSave(
          'current_balance',
          '\$${activeChallenge.currentBalance.toStringAsFixed(2)}',
        );
        await _safeSave(
          'target_balance',
          '\$${activeChallenge.targetBalance.toStringAsFixed(0)}',
        );
        await _safeSave('pace_status', paceLabel);
        await _safeSave(
          'required_today',
          reqToday >= 0
              ? '+\$${reqToday.toStringAsFixed(2)} req.'
              : '\$${reqToday.toStringAsFixed(2)} req.',
        );
      } else {
        await _safeSave('challenge_name', 'No Active Challenge');
        await _safeSave('current_balance', '\$0.00');
        await _safeSave('target_balance', '\$0');
        await _safeSave('pace_status', 'No Data');
        await _safeSave('required_today', 'Create a challenge');
      }

      if (profile != null) {
        await _safeSave(
          'trader_level',
          'Lvl ${profile.level} ${profile.levelTitle}',
        );
      }

      await _safeUpdate();
    } catch (_) {}
  }
}
