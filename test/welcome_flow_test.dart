import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_game/main.dart';
import 'package:task_game/providers/challenges_provider.dart';
import 'package:task_game/providers/profile_provider.dart';

void main() {
  testWidgets('first launch shows the welcome screen; entering a name unlocks the dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final challengesProvider = ChallengesProvider();
    await challengesProvider.load();
    final profileProvider = ProfileProvider();
    await profileProvider.load();

    expect(profileProvider.hasProfile, isFalse);

    await tester.pumpWidget(TradeChallengeApp(
      challengesProvider: challengesProvider,
      profileProvider: profileProvider,
    ));
    // The welcome screen runs a staggered entrance animation; let it finish.
    await tester.pumpAndSettle();

    expect(find.text('Trade Journey'), findsOneWidget);
    expect(find.byKey(const Key('welcomeNameField')), findsOneWidget);

    // The button starts disabled until a name is entered.
    final buttonBefore = tester.widget<ButtonStyleButton>(find.byKey(const Key('welcomeGetStartedButton')));
    expect(buttonBefore.onPressed, isNull);

    await tester.enterText(find.byKey(const Key('welcomeNameField')), 'Ada Lovelace');
    await tester.pump();
    await tester.tap(find.byKey(const Key('welcomeGetStartedButton')));
    await tester.pumpAndSettle();

    // Lands on the (empty) dashboard, and the profile is persisted.
    expect(find.text('No trade challenges yet'), findsOneWidget);

    final reloaded = ProfileProvider();
    await reloaded.load();
    expect(reloaded.profile?.name, 'Ada Lovelace');
  });
}
