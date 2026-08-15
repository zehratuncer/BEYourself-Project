import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:be_yourself/core/constants/app_strings.dart';
import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/features/settings/presentation/pages/settings_page.dart';
import 'package:be_yourself/main.dart';

void main() {
  testWidgets('WelcomePage smoke test in light mode', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'isDarkMode': false});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    );

    final appNameFinder = find.text(AppStrings.appName);
    expect(appNameFinder, findsOneWidget);
    final Text appNameText = tester.widget(appNameFinder);
    expect(appNameText.style?.color, AppColors.primaryBlue);

    expect(find.text(AppStrings.welcomeSubtitle), findsOneWidget);

    // Advance timer past splash duration
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('WelcomePage renders visible brand colored title in dark mode', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'isDarkMode': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    );

    final appNameFinder = find.text(AppStrings.appName);
    expect(appNameFinder, findsOneWidget);
    final Text appNameText = tester.widget(appNameFinder);
    // In dark mode, title must still be brand blue and NOT white/invisible
    expect(appNameText.style?.color, AppColors.primaryBlue);

    final subtitleFinder = find.text(AppStrings.welcomeSubtitle);
    expect(subtitleFinder, findsOneWidget);
    final Text subtitleText = tester.widget(subtitleFinder);
    expect(subtitleText.style?.color, AppColors.lightTextSecondary);

    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}

