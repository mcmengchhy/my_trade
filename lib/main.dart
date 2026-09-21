import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/challenges_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final challengesProvider = ChallengesProvider();
  final profileProvider = ProfileProvider();
  try {
    await Future.wait([challengesProvider.load(), profileProvider.load()]);
  } catch (e) {
    debugPrint('Error loading initial providers: $e');
  }
  runApp(TradeChallengeApp(
    challengesProvider: challengesProvider,
    profileProvider: profileProvider,
  ));
}

class TradeChallengeApp extends StatelessWidget {
  const TradeChallengeApp({
    super.key,
    required this.challengesProvider,
    required this.profileProvider,
  });

  final ChallengesProvider challengesProvider;
  final ProfileProvider profileProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: challengesProvider),
        ChangeNotifierProvider.value(value: profileProvider),
      ],
      child: MaterialApp(
        title: 'Trade Journey',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: profileProvider.hasProfile ? const DashboardScreen() : const WelcomeScreen(),
      ),
    );
  }
}
