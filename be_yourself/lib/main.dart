import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:be_yourself/core/constants/app_strings.dart';
import 'package:be_yourself/core/theme/app_theme.dart';
import 'package:be_yourself/features/home_widget/services/home_widget_service.dart';
import 'package:be_yourself/features/media/services/media_storage_service.dart';
import 'package:be_yourself/features/notifications/data/datasources/notification_service.dart';
import 'package:be_yourself/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:be_yourself/features/settings/presentation/pages/settings_page.dart';

import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError.onError caught: ${details.exceptionAsString()}');
    };

    final prefs = await SharedPreferences.getInstance();

    try {
      await NotificationService.instance.initialize();
    } catch (e) {
      debugPrint('Notification service init error: $e');
    }

    try {
      await HomeWidgetService.instance.initialize();
    } catch (e) {
      debugPrint('HomeWidget service init error: $e');
    }

    try {
      await MediaStorageService.instance.init();
    } catch (e) {
      debugPrint('MediaStorageService init error: $e');
    }

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    );

    // Check if app was launched via notification or home widget click
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        NotificationService.instance.checkPendingNotificationLaunch();
      } catch (e) {
        debugPrint('checkPendingNotificationLaunch error: $e');
      }
      try {
        HomeWidgetService.instance.checkPendingWidgetLaunch();
      } catch (e) {
        debugPrint('checkPendingWidgetLaunch error: $e');
      }
    });
  }, (error, stackTrace) {
    debugPrint('Uncaught asynchronous error: $error\n$stackTrace');
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const WelcomePage(),
    );
  }
}

