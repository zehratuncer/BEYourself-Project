import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:be_yourself/core/config/supabase_config.dart';
import 'package:be_yourself/features/profile/domain/entities/user_profile.dart';
import 'package:be_yourself/main.dart';

class ProfileNotifier extends StateNotifier<UserProfile> {
  ProfileNotifier(this.prefs) : super(UserProfile.defaultProfile) {
    _loadProfile();
    _syncWithRemote();
  }

  final SharedPreferences prefs;
  static const String _profileKey = 'user_profile_data_v1';

  String get _deviceId => prefs.getString('user_device_private_uuid') ?? '';

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

  Future<void> _syncWithRemote() async {
    final client = SupabaseConfig.client;
    if (client == null || _deviceId.isEmpty) return;

    try {
      final response = await client
          .from('user_profiles')
          .select()
          .eq('device_id', _deviceId)
          .maybeSingle();

      if (response != null) {
        state = UserProfile(
          name: response['name']?.toString() ?? state.name,
          motto: response['motto']?.toString() ?? state.motto,
          avatarEmoji:
              response['avatar_emoji']?.toString() ?? state.avatarEmoji,
          avatarPath: response['avatar_path']?.toString(),
          greetingStyle:
              response['greeting_style']?.toString() ?? state.greetingStyle,
        );
        _persist();
      } else {
        _pushToRemote();
      }
    } catch (_) {}
  }

  Future<void> _pushToRemote() async {
    final client = SupabaseConfig.client;
    if (client == null || _deviceId.isEmpty) return;

    try {
      await client.from('user_profiles').upsert({
        'device_id': _deviceId,
        'name': state.name,
        'motto': state.motto,
        'avatar_emoji': state.avatarEmoji,
        'avatar_path': state.avatarPath,
        'greeting_style': state.greetingStyle,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  void _persist() {
    prefs.setString(_profileKey, jsonEncode(state.toJson()));
  }

  void updateName(String name) {
    state = state.copyWith(name: name.trim());
    _persist();
    _pushToRemote();
  }

  void updateMotto(String motto) {
    state = state.copyWith(motto: motto.trim());
    _persist();
    _pushToRemote();
  }

  void setAvatarPath(String? path) {
    if (path == null) {
      state = state.copyWith(clearAvatarPath: true);
    } else {
      state = state.copyWith(avatarPath: path);
    }
    _persist();
    _pushToRemote();
  }

  void setAvatarEmoji(String emoji) {
    state = state.copyWith(avatarEmoji: emoji, clearAvatarPath: true);
    _persist();
    _pushToRemote();
  }

  void setGreetingStyle(String style) {
    state = state.copyWith(greetingStyle: style);
    _persist();
    _pushToRemote();
  }

  void resetToDefaults() {
    state = UserProfile.defaultProfile;
    _persist();
    _pushToRemote();
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, UserProfile>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfileNotifier(prefs);
});
