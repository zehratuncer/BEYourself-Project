import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:be_yourself/features/profile/domain/entities/user_profile.dart';
import 'package:be_yourself/main.dart';

class ProfileNotifier extends StateNotifier<UserProfile> {
  ProfileNotifier(this.prefs) : super(UserProfile.defaultProfile) {
    _loadProfile();
  }

  final SharedPreferences prefs;
  static const String _profileKey = 'user_profile_data_v1';

  void _loadProfile() {
    final raw = prefs.getString(_profileKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        state = UserProfile.fromJson(map);
      } catch (e) {
        state = UserProfile.defaultProfile;
      }
    }
  }

  void _persist() {
    prefs.setString(_profileKey, jsonEncode(state.toJson()));
  }

  void updateName(String name) {
    state = state.copyWith(name: name.trim());
    _persist();
  }

  void updateMotto(String motto) {
    state = state.copyWith(motto: motto.trim());
    _persist();
  }

  void setAvatarPath(String? path) {
    if (path == null) {
      state = state.copyWith(clearAvatarPath: true);
    } else {
      state = state.copyWith(avatarPath: path);
    }
    _persist();
  }

  void setAvatarEmoji(String emoji) {
    state = state.copyWith(avatarEmoji: emoji, clearAvatarPath: true);
    _persist();
  }

  void setGreetingStyle(String style) {
    state = state.copyWith(greetingStyle: style);
    _persist();
  }

  void resetToDefaults() {
    state = UserProfile.defaultProfile;
    _persist();
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, UserProfile>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfileNotifier(prefs);
});
