import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:be_yourself/features/notifications/data/datasources/notification_service.dart';
import 'package:be_yourself/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:be_yourself/features/quote/presentation/providers/quote_providers.dart';
import 'package:be_yourself/features/settings/presentation/pages/settings_page.dart';
import 'package:be_yourself/main.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

final notificationSyncProvider = Provider<void>((ref) {
  final isEnabled = ref.watch(dailyNotificationEnabledProvider);
  final count = ref.watch(notificationCountProvider);
  final startTime = ref.watch(notificationStartTimeProvider);
  final endTime = ref.watch(notificationEndTimeProvider);
  final quotes = ref.watch(quoteListProvider);
  final service = ref.watch(notificationServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  if (!isEnabled) {
    service.cancelAll();
    return;
  }

  // Sync scheduled notifications with current settings and active quotes list
  service.scheduleDailyQuoteNotifications(
    count: count,
    startTime: startTime,
    endTime: endTime,
    quotes: quotes,
    prefs: prefs,
  );
});

