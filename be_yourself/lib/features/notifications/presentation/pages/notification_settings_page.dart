import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:be_yourself/core/theme/app_colors.dart';
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
    final count = ref.watch(notificationCountProvider);
    final startTime = ref.watch(notificationStartTimeProvider);
    final endTime = ref.watch(notificationEndTimeProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

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
              'Gün içinde kaç bildirim almak istediğinizi ve saat aralığını seçin.',
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
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
                      Text(
                        '$count Adet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode
                              ? AppColors.primaryBlueLight
                              : AppColors.primaryBlue,
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
                        fontWeight: FontWeight.w600,
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
                        fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }
}

