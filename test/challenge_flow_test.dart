import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_game/main.dart';
import 'package:task_game/providers/challenges_provider.dart';
import 'package:task_game/providers/profile_provider.dart';

void main() {
  testWidgets('create a challenge, log a trade, and persist across restart', (tester) async {
    // Use a tall surface so the forms render fully without needing to scroll
    // to reach fields/buttons below the fold.
    tester.view.physicalSize = const Size(800, 2400);
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

    // Starts on the empty dashboard.
    expect(find.text('No trade challenges yet'), findsOneWidget);
    await tester.tap(find.text('Create your first challenge'));
    await tester.pumpAndSettle();

    // Fill out the new-challenge form: $10 -> $1000 in 20 days.
    expect(find.text('New Challenge'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('challengeNameField')), 'Test Challenge');
    await tester.enterText(find.byKey(const Key('startBalanceField')), '10');
    await tester.enterText(find.byKey(const Key('targetBalanceField')), '1000');
    await tester.tap(find.byKey(const Key('createChallengeButton')));
    await tester.pumpAndSettle();

    // Back on the dashboard with the new challenge card showing day 1 of 20.
    expect(find.text('Test Challenge'), findsOneWidget);
    expect(find.textContaining('Day 1 of 20'), findsOneWidget);

    // Open the challenge detail screen.
    await tester.tap(find.text('Test Challenge'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('currentBalanceText')), findsOneWidget);
    expect(find.text('\$10.00'), findsOneWidget);

    // Log a winning trade.
    await tester.tap(find.text('Log trade'));
    await tester.pumpAndSettle();
    expect(find.text('Log Trade'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('pnlField')), '5');
    await tester.tap(find.byKey(const Key('saveTradeButton')));
    await tester.pumpAndSettle();

    // Balance on the detail screen reflects the trade.
    expect(find.text('\$15.00'), findsOneWidget);

    // Simulate an app restart by reloading from the persisted store.
    final restartedChallenges = ChallengesProvider();
    await restartedChallenges.load();
    expect(restartedChallenges.challenges, hasLength(1));
    final reloaded = restartedChallenges.challenges.first;
    expect(reloaded.name, 'Test Challenge');
    expect(reloaded.currentBalance, 15.0);
    expect(reloaded.trades, hasLength(1));

    final restartedProfile = ProfileProvider();
    await restartedProfile.load();
    expect(restartedProfile.profile?.name, 'Test User');

    await tester.pumpWidget(TradeChallengeApp(
      challengesProvider: restartedChallenges,
      profileProvider: restartedProfile,
    ));
    await tester.pumpAndSettle();
    expect(find.text('Test Challenge'), findsOneWidget);
  });
}
