import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/features/notifications/data/datasources/notification_service.dart';
import 'package:be_yourself/features/notifications/presentation/providers/notification_providers.dart';
import 'package:be_yourself/features/quote/presentation/providers/quote_providers.dart';
import 'package:be_yourself/features/settings/presentation/pages/settings_page.dart';
import 'package:be_yourself/main.dart';

class NotificationCountNotifier extends StateNotifier<int> {
  final SharedPreferences prefs;
  NotificationCountNotifier(this.prefs)
      : super(prefs.getInt('notificationCount') ?? 3);

  void setCount(int val) {
    state = val;
    prefs.setInt('notificationCount', val);
  }
}

final notificationCountProvider =
    StateNotifierProvider<NotificationCountNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationCountNotifier(prefs);
});

class NotificationStartTimeNotifier extends StateNotifier<TimeOfDay> {
  final SharedPreferences prefs;
  NotificationStartTimeNotifier(this.prefs)
      : super(
          TimeOfDay(
            hour: prefs.getInt('notificationStartTimeHour') ?? 9,
            minute: prefs.getInt('notificationStartTimeMinute') ?? 0,
          ),
        );

  void setTime(TimeOfDay time) {
    state = time;
    prefs.setInt('notificationStartTimeHour', time.hour);
    prefs.setInt('notificationStartTimeMinute', time.minute);
  }
}

final notificationStartTimeProvider =
    StateNotifierProvider<NotificationStartTimeNotifier, TimeOfDay>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationStartTimeNotifier(prefs);
});

class NotificationEndTimeNotifier extends StateNotifier<TimeOfDay> {
  final SharedPreferences prefs;
  NotificationEndTimeNotifier(this.prefs)
      : super(
          TimeOfDay(
            hour: prefs.getInt('notificationEndTimeHour') ?? 21,
            minute: prefs.getInt('notificationEndTimeMinute') ?? 0,
          ),
        );

  void setTime(TimeOfDay time) {
    state = time;
    prefs.setInt('notificationEndTimeHour', time.hour);
    prefs.setInt('notificationEndTimeMinute', time.minute);
  }
}

final notificationEndTimeProvider =
    StateNotifierProvider<NotificationEndTimeNotifier, TimeOfDay>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationEndTimeNotifier(prefs);
});

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Automatically trigger notification schedule sync on change
    ref.watch(notificationSyncProvider);

    final count = ref.watch(notificationCountProvider);
    final startTime = ref.watch(notificationStartTimeProvider);
    final endTime = ref.watch(notificationEndTimeProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final quotes = ref.watch(quoteListProvider);

    final cardBgColor = Theme.of(context).cardColor;
    final primaryTextColor = isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryTextColor = isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Bildirim Ayarları',
          style: TextStyle(
            color: isDarkMode
                ? AppColors.darkTextPrimary
                : const Color(0xFF111C2D),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode
              ? AppColors.primaryBlueLight
              : AppColors.primaryBlue,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            Text(
              'Günlük Hatırlatıcılar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? AppColors.primaryBlueLight
                    : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gün içinde kaç bildirim almak istediğinizi ve saat aralığını seçin. Bildirimleriniz otomatik olarak gün içine eşit dağıtılır.',
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Daily Count Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withAlpha(50)
                        : const Color(0xFF60A5FA).withAlpha(15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Günlük Bildirim Sıklığı',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (isDarkMode
                                  ? AppColors.primaryBlueLight
                                  : AppColors.primaryBlue)
                              .withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count Kez / Gün',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? AppColors.primaryBlueLight
                                : AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: count.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: isDarkMode
                        ? AppColors.primaryBlueLight
                        : AppColors.primaryBlue,
                    onChanged: (val) {
                      ref
                          .read(notificationCountProvider.notifier)
                          .setCount(val.toInt());
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Time Range Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withAlpha(50)
                        : const Color(0xFF60A5FA).withAlpha(15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wb_sunny_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Başlangıç Saati',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                      ),
                    ),
                    trailing: Text(
                      startTime.format(context),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? AppColors.primaryBlueLight
                            : AppColors.primaryBlue,
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        ref
                            .read(notificationStartTimeProvider.notifier)
                            .setTime(picked);
                      }
                    },
                  ),
                  Divider(
                    height: 1,
                    color: isDarkMode
                        ? AppColors.darkDivider
                        : AppColors.lightDivider,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.nights_stay_rounded,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Bitiş Saati',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                      ),
                    ),
                    trailing: Text(
                      endTime.format(context),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? AppColors.primaryBlueLight
                            : AppColors.primaryBlue,
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (picked != null) {
                        ref
                            .read(notificationEndTimeProvider.notifier)
                            .setTime(picked);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action: Test Notification Button
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [
                          AppColors.primaryBlueLight,
                          const Color(0xFF60A5FA),
                        ]
                      : [
                          AppColors.primaryBlue,
                          const Color(0xFF3B82F6),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDarkMode
                            ? AppColors.primaryBlueLight
                            : AppColors.primaryBlue)
                        .withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  HapticFeedback.mediumImpact();

                  try {
                    // Request permissions if needed
                    await NotificationService.instance.requestPermissions();

                    // Pick sample text
                    final sampleQuote = quotes.isNotEmpty
                        ? quotes.first.displayText
                        : 'Kendine inan, yapabileceklerinin sınırı yoktur.';
                    final sampleAuthor = quotes.isNotEmpty
                        ? quotes.first.author
                        : 'BeYourself';

                    await NotificationService.instance.showInstantNotification(
                      title: 'BeYourself • $sampleAuthor',
                      body: sampleQuote,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Colors.white),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Test bildirimi gönderildi! Bildirim çubuğunu kontrol edin.',
                                ),
                              ),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Bildirim hatası: $e'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.notifications_active_rounded,
                    color: Colors.white),
                label: const Text(
                  '🔔 Test Bildirimi Gönder',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Permission Request Card
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final granted =
                      await NotificationService.instance.requestPermissions();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          granted
                              ? 'Bildirim izni onaylandı! 🎉'
                              : 'Bildirim izni reddedildi veya henüz verilmedi. Telefon ayarlarından BeYourself için bildirimleri açabilirsiniz.',
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: granted
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('İzin kontrol hatası: $e'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.security_rounded),
              label: const Text('Bildirim İznini Kontrol Et / İste'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


