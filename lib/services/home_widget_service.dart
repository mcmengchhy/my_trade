import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../models/challenge.dart';
import '../models/user_profile.dart';
import '../utils/challenge_math.dart';
import '../widgets/widget_monthly_heatmap.dart';
import '../widgets/widget_sparkline_chart.dart';

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
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (_) {}
  }

  static Future<void> _safeUpdate() async {
    try {
      await HomeWidget.updateWidget(
        name: _iOSWidgetName,
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      ).timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (_) {}
  }

  /// Syncs active challenge balance, required daily profit, pace status,
  /// current month heatmap chart, and trader level data to native Android & iOS Home Widgets.
  static Future<void> syncData({
    Challenge? activeChallenge,
    UserProfile? profile,
    bool enabled = true,
    bool syncChallenge = true,
  }) async {
    if (_isTest) return;
    try {
      await HomeWidget.setAppGroupId('group.com.tradejourney.app');
      if (!enabled) {
        await _safeSave('challenge_name', 'Widget Disabled');
        await _safeSave('current_balance', '\$0.00');
        await _safeSave('target_balance', '\$0');
        await _safeSave('pace_status', 'Off');
        await _safeSave('required_today', 'Enable in settings');
        await _safeSave('chart_path', '');
      } else if (syncChallenge) {
        if (activeChallenge != null) {
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

          // Render GitHub-style monthly activity heatmap offscreen for Home Screen Widget
          try {
            await HomeWidget.renderFlutterWidget(
              WidgetMonthlyHeatmap(challenge: activeChallenge),
              key: 'chart_path',
              logicalSize: const Size(320, 110),
              pixelRatio: 2.0,
            ).timeout(const Duration(seconds: 3), onTimeout: () => null);
          } catch (_) {}
        } else {
          await _safeSave('challenge_name', 'No Active Challenge');
          await _safeSave('current_balance', '\$0.00');
          await _safeSave('target_balance', '\$0');
          await _safeSave('pace_status', 'No Data');
          await _safeSave('required_today', 'Create a challenge');
          await _safeSave('chart_path', '');
        }
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
