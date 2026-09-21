import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/challenge.dart';
import '../models/user_profile.dart';

class StorageService {
  static const _challengesKey = 'challenges';
  static const _profileKey = 'user_profile';
  static const _widgetEnabledKey = 'is_widget_enabled';
  static const _widgetChallengeIdKey = 'selected_widget_challenge_id';

  Future<List<Challenge>> loadChallenges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_challengesKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Challenge.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveChallenges(List<Challenge> challenges) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(challenges.map((c) => c.toJson()).toList());
      await prefs.setString(_challengesKey, raw);
    } catch (_) {}
  }

  Future<UserProfile?> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_profileKey);
      if (raw == null || raw.isEmpty) return null;
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    } catch (_) {}
  }

  Future<bool> loadWidgetEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_widgetEnabledKey) ?? true;
  }

  Future<void> saveWidgetEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_widgetEnabledKey, enabled);
  }

  Future<String?> loadSelectedWidgetChallengeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_widgetChallengeIdKey);
  }

  Future<void> saveSelectedWidgetChallengeId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await prefs.remove(_widgetChallengeIdKey);
    } else {
      await prefs.setString(_widgetChallengeIdKey, id);
    }
  }
}
