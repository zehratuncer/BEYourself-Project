import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:be_yourself/core/constants/app_strings.dart';
import 'package:be_yourself/main.dart';

void main() {
  testWidgets('WelcomePage smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.welcomeSubtitle), findsOneWidget);

    // Advance timer past splash duration
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}

