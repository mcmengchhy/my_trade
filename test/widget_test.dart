import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_game/main.dart';
import 'package:task_game/providers/challenges_provider.dart';
import 'package:task_game/providers/profile_provider.dart';

void main() {
  testWidgets('Dashboard shows empty state when there are no challenges', (tester) async {
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

    expect(find.text('No trade challenges yet'), findsOneWidget);
    expect(find.text('Create your first challenge'), findsOneWidget);
  });
}
