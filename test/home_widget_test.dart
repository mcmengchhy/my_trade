import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_game/models/challenge.dart';
import 'package:task_game/models/user_profile.dart';
import 'package:task_game/providers/challenges_provider.dart';
import 'package:task_game/services/home_widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('HomeWidgetService handles enabled, disabled, and active challenges gracefully', () async {
    // 1. Sync null active challenge & profile
    await expectLater(
      HomeWidgetService.syncData(activeChallenge: null, profile: null, enabled: true),
      completes,
    );

    // 2. Sync with disabled mode
    await expectLater(
      HomeWidgetService.syncData(activeChallenge: null, profile: null, enabled: false),
      completes,
    );

    // 3. Sync with active challenge & profile
    final challenge = Challenge(
      id: 'c_test',
      name: '10k Challenge',
      startBalance: 10000,
      targetBalance: 12000,
      durationDays: 30,
      startDate: DateTime.now(),
    );
    final profile = UserProfile(
      name: 'Trader Pro',
      createdAt: DateTime.now(),
      xp: 250,
    );

    await expectLater(
      HomeWidgetService.syncData(activeChallenge: challenge, profile: profile, enabled: true),
      completes,
    );
  });

  test('ChallengesProvider manages widget enabled state and selected challenge selection', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = ChallengesProvider();
    await provider.load();

    expect(provider.isWidgetEnabled, isTrue);
    expect(provider.selectedWidgetChallengeId, isNull);

    // 1. Add 2 challenges
    await provider.addChallenge(
      name: 'Challenge 1',
      startBalance: 1000,
      targetBalance: 2000,
      durationDays: 30,
      startDate: DateTime.now(),
    );
    await provider.addChallenge(
      name: 'Challenge 2',
      startBalance: 5000,
      targetBalance: 10000,
      durationDays: 30,
      startDate: DateTime.now(),
    );

    expect(provider.challenges.length, 2);
    final c2Id = provider.challenges[1].id;

    // 2. Explicitly select Challenge 2 for Home Widget
    await provider.setSelectedWidgetChallengeId(c2Id);
    expect(provider.selectedWidgetChallengeId, c2Id);

    // 3. Toggle Home Widget OFF
    await provider.setWidgetEnabled(false);
    expect(provider.isWidgetEnabled, isFalse);

    // 4. Toggle Home Widget back ON
    await provider.setWidgetEnabled(true);
    expect(provider.isWidgetEnabled, isTrue);

    // 5. Reset to Auto selection
    await provider.setSelectedWidgetChallengeId(null);
    expect(provider.selectedWidgetChallengeId, isNull);
  });
}
