import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_game/main.dart';
import 'package:task_game/providers/challenges_provider.dart';
import 'package:task_game/providers/profile_provider.dart';

void main() {
  testWidgets(
    'trading rules, a richer trade journal, and derived discipline stats all wire through end to end',
    (tester) async {
      // Tall surface so the longer forms render fully without scrolling.
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});

      final challengesProvider = ChallengesProvider();
      await challengesProvider.load();
      final profileProvider = ProfileProvider();
      await profileProvider.load();
      await profileProvider.setName('Test User');

      await tester.pumpWidget(TradeChallengeApp(
        challengesProvider: challengesProvider,
        profileProvider: profileProvider,
      ));
      await tester.pumpAndSettle();

      // Create a challenge with two trading rules and a daily loss limit.
      await tester.tap(find.text('Create your first challenge'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('challengeNameField')), 'Discipline Test');
      await tester.tap(find.text('Risk max 1% per trade'));
      await tester.tap(find.text('Always use a stop loss'));
      await tester.enterText(find.byKey(const Key('maxDailyLossField')), '2');
      await tester.tap(find.byKey(const Key('createChallengeButton')));
      await tester.pumpAndSettle();

      // Open the challenge and confirm the rules made it through.
      await tester.tap(find.text('Discipline Test'));
      await tester.pumpAndSettle();
      expect(find.text('Trading rules'), findsOneWidget);
      expect(find.text('Risk max 1% per trade'), findsOneWidget);
      expect(find.text('Always use a stop loss'), findsOneWidget);

      // Log a trade with the richer journal fields: a profitable trade that
      // still broke the trader's plan (realistic — profit isn't discipline).
      await tester.tap(find.text('Log trade'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('setupDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Breakout').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('pnlField')), '15');
      await tester.tap(find.text('No')); // "Did you follow your plan?" -> No
      await tester.tap(find.text('Revenge')); // emotion
      await tester.enterText(
        find.byKey(const Key('lessonField')),
        'Waited too long for confirmation and chased the move.',
      );
      await tester.tap(find.byKey(const Key('saveTradeButton')));
      await tester.pumpAndSettle();

      // Performance stats derived from that single trade.
      expect(find.text('100%'), findsOneWidget); // win rate
      expect(find.text('0%'), findsOneWidget); // plan adherence (didn't follow plan)
      // Shows up on trade tile, avg win stat, and emotion item.
      expect(find.text('+\$15.00'), findsWidgets);
      expect(find.textContaining('Breakout'), findsWidgets); // shows on the trade tile

      // Rules are still there after the round trip.
      expect(find.text('Risk max 1% per trade'), findsOneWidget);
    },
  );
}
