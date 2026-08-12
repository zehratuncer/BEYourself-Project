import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:be_yourself/features/settings/presentation/pages/settings_page.dart';
import 'package:be_yourself/shared/providers/navigation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings & Navigation Unit Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('DarkModeNotifier initializes from prefs and toggles', () {
      final notifier = DarkModeNotifier(prefs);

      // Default is false
      expect(notifier.state, isFalse);

      // Toggle to dark mode
      notifier.toggle(true);
      expect(notifier.state, isTrue);
      expect(prefs.getBool('isDarkMode'), isTrue);

      // Simulate app restart
      final reloadedNotifier = DarkModeNotifier(prefs);
      expect(reloadedNotifier.state, isTrue);

      // Toggle back to light mode
      reloadedNotifier.toggle(false);
      expect(reloadedNotifier.state, isFalse);
      expect(prefs.getBool('isDarkMode'), isFalse);
    });

    test('currentTabProvider changes tab index', () {
      final container = ProviderContainer();

      expect(container.read(currentTabProvider), 0);

      container.read(currentTabProvider.notifier).state = 2;
      expect(container.read(currentTabProvider), 2);

      container.read(currentTabProvider.notifier).state = 1;
      expect(container.read(currentTabProvider), 1);
    });
  });
}
