import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseConfig {
  SupabaseConfig._();

  // Configurable credentials
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://itsrmpfmnnolwvvmrsye.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable__cvHjyLnRlb10H9eoZPdyg_ohx9BC2v',
  );

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Initializes Supabase gracefully. If credentials are dummy/offline, continues in offline mode.
  static Future<void> init() async {
    if (supabaseUrl.contains('dummy') ||
        supabaseAnonKey.contains('dummy') ||
        supabaseUrl.isEmpty ||
        supabaseAnonKey.isEmpty) {
      debugPrint('ℹ️ Supabase running in local/offline fallback mode.');
      _isInitialized = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('✅ Supabase connected successfully.');
    } catch (e) {
      debugPrint('⚠️ Supabase init error (offline fallback active): $e');
      _isInitialized = false;
    }
  }

  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}

/// Manages permanent, private device UUID for zero-auth user isolation.
class DeviceIdManager {
  static const String _deviceIdKey = 'user_device_private_uuid';

  static Future<String> getOrCreateDeviceId(SharedPreferences prefs) async {
    var deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null || deviceId.trim().isEmpty) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
      debugPrint('Generated new private Device ID: $deviceId');
    }
    return deviceId;
  }
}
