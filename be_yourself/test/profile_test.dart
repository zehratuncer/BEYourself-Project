import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:be_yourself/features/profile/domain/entities/user_profile.dart';
import 'package:be_yourself/features/profile/presentation/pages/profile_settings_page.dart';
import 'package:be_yourself/features/profile/presentation/providers/profile_providers.dart';
import 'package:be_yourself/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProfile Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('UserProfile JSON serialization and default values', () {
      const defaultProfile = UserProfile.defaultProfile;
      expect(defaultProfile.name, 'Zehra Tuncer');
      expect(defaultProfile.avatarEmoji, '💫');
      expect(defaultProfile.avatarPath, isNull);

      final json = defaultProfile.toJson();
      final fromJson = UserProfile.fromJson(json);

      expect(fromJson.name, defaultProfile.name);
      expect(fromJson.motto, defaultProfile.motto);
      expect(fromJson.greetingStyle, defaultProfile.greetingStyle);
    });

    test('ProfileNotifier updates and persists name and motto', () {
      final notifier = ProfileNotifier(prefs);

      expect(notifier.state.name, 'Zehra Tuncer');

      notifier.updateName('Zehra Yılmaz');
      expect(notifier.state.name, 'Zehra Yılmaz');

      notifier.updateMotto('Hayatı sev, kendini keşfet.');
      expect(notifier.state.motto, 'Hayatı sev, kendini keşfet.');

      // Simulate app restart
      final reloadedNotifier = ProfileNotifier(prefs);
      expect(reloadedNotifier.state.name, 'Zehra Yılmaz');
      expect(reloadedNotifier.state.motto, 'Hayatı sev, kendini keşfet.');
    });

    test('ProfileNotifier updates avatar emoji and path', () {
      final notifier = ProfileNotifier(prefs);

      notifier.setAvatarEmoji('🌸');
      expect(notifier.state.avatarEmoji, '🌸');
      expect(notifier.state.avatarPath, isNull);

      notifier.setAvatarPath('/path/to/custom_avatar.png');
      expect(notifier.state.avatarPath, '/path/to/custom_avatar.png');

      notifier.setAvatarEmoji('🚀');
      expect(notifier.state.avatarEmoji, '🚀');
      expect(notifier.state.avatarPath, isNull);
    });

    test('ProfileNotifier resets to defaults', () {
      final notifier = ProfileNotifier(prefs);

      notifier.updateName('Yeni İsim');
      notifier.setGreetingStyle('motivational');

      expect(notifier.state.name, 'Yeni İsim');
      expect(notifier.state.greetingStyle, 'motivational');

      notifier.resetToDefaults();
      expect(notifier.state.name, 'Zehra Tuncer');
      expect(notifier.state.greetingStyle, 'friendly');
    });

    testWidgets('ProfileSettingsPage saves and pops back on check icon', (tester) async {
      final notifier = ProfileNotifier(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            profileProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileSettingsPage(),
                        ),
                      );
                    },
                    child: const Text('Open Settings'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Open ProfileSettingsPage
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Profil Ayarları'), findsOneWidget);
      expect(find.byTooltip('Kaydet'), findsOneWidget);

      // Tap the AppBar check icon
      await tester.tap(find.byTooltip('Kaydet'));
      await tester.pumpAndSettle();

      // Verify it popped back to the parent page
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Profil Ayarları'), findsNothing);
      expect(find.text('Profil bilgileri kaydedildi! ✨'), findsOneWidget);
    });
  });
}
