import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:be_yourself/core/constants/app_constants.dart';
import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:be_yourself/features/profile/presentation/pages/profile_settings_page.dart';
import 'package:be_yourself/features/profile/presentation/providers/profile_providers.dart';
import 'package:be_yourself/main.dart';

class DarkModeNotifier extends StateNotifier<bool> {
  final SharedPreferences prefs;
  DarkModeNotifier(this.prefs) : super(prefs.getBool('isDarkMode') ?? false);

  void toggle(bool value) {
    state = value;
    prefs.setBool('isDarkMode', value);
  }
}

final isDarkModeProvider =
    StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DarkModeNotifier(prefs);
});

class DailyNotificationNotifier extends StateNotifier<bool> {
  final SharedPreferences prefs;
  DailyNotificationNotifier(this.prefs)
      : super(prefs.getBool('dailyNotificationEnabled') ?? true);

  void toggle(bool value) {
    state = value;
    prefs.setBool('dailyNotificationEnabled', value);
  }
}

final dailyNotificationEnabledProvider =
    StateNotifierProvider<DailyNotificationNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DailyNotificationNotifier(prefs);
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final dailyNotifications = ref.watch(dailyNotificationEnabledProvider);
    final cardBgColor = Theme.of(context).cardColor;
    final primaryTextColor = isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryTextColor = isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final userProfile = ref.watch(profileProvider);
    final hasCustomPhoto = userProfile.avatarPath != null &&
        File(userProfile.avatarPath!).existsSync();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            Text(
              'Ayarlar',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? AppColors.primaryBlueLight
                    : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),

            // Profile Card (Clickable -> ProfileSettingsPage)
            Container(
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
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileSettingsPage(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryBlue
                                .withAlpha(isDarkMode ? 35 : 20),
                            border: Border.all(
                              color: isDarkMode
                                  ? AppColors.primaryBlueLight.withAlpha(60)
                                  : AppColors.primaryBlue.withAlpha(30),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: hasCustomPhoto
                                ? Image.file(
                                    File(userProfile.avatarPath!),
                                    fit: BoxFit.cover,
                                    width: 58,
                                    height: 58,
                                  )
                                : Center(
                                    child: Text(
                                      userProfile.avatarEmoji,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userProfile.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 14,
                                    color: isDarkMode
                                        ? AppColors.primaryBlueLight
                                        : AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Profil Ayarları',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? AppColors.primaryBlueLight
                                          : AppColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: secondaryTextColor.withAlpha(140),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),
            _SectionHeader(title: 'BİLDİRİM VE TEMA', isDarkMode: isDarkMode),

            // Notification & Theme section
            Container(
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
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Günlük Bildirimler',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      subtitle: Text(
                        'Günün ilham veren sözlerini al',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                      value: dailyNotifications,
                      activeThumbColor: isDarkMode
                          ? AppColors.primaryBlueLight
                          : AppColors.primaryBlue,
                      activeTrackColor: AppColors.primaryBlue.withAlpha(100),
                      onChanged: (val) {
                        ref
                            .read(dailyNotificationEnabledProvider.notifier)
                            .toggle(val);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              val
                                  ? 'Günlük bildirimler aktif edildi.'
                                  : 'Günlük bildirimler kapatıldı.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDarkMode
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.notifications_active_outlined,
                        color: isDarkMode
                            ? AppColors.primaryBlueLight
                            : AppColors.primaryBlue,
                      ),
                      title: Text(
                        'Bildirim Tercihleri',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      subtitle: Text(
                        'Saat ve sıklık aralığını ayarla',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: secondaryTextColor,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsPage(),
                          ),
                        );
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDarkMode
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                    ),
                    SwitchListTile(
                      title: Text(
                        'Karanlık Mod',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      subtitle: Text(
                        'Gece gözlerinizi yormayan görünüm',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                      value: isDarkMode,
                      activeThumbColor: isDarkMode
                          ? AppColors.primaryBlueLight
                          : AppColors.primaryBlue,
                      activeTrackColor: AppColors.primaryBlue.withAlpha(100),
                      onChanged: (val) {
                        ref.read(isDarkModeProvider.notifier).toggle(val);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),
            _SectionHeader(title: 'UYGULAMA BİLGİLERİ', isDarkMode: isDarkMode),

            // App info section
            Container(
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
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: isDarkMode
                            ? AppColors.primaryBlueLight
                            : AppColors.primaryBlue,
                      ),
                      title: Text(
                        'Sürüm',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      trailing: Text(
                        'v1.0.0 (Offline)',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDarkMode
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.share_outlined,
                        color: isDarkMode
                            ? AppColors.primaryBlueLight
                            : AppColors.primaryBlue,
                      ),
                      title: Text(
                        'Uygulamayı Paylaş',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: secondaryTextColor,
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('BeYourself uygulamasını sevdiklerinizle paylaşın!'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isDarkMode});

  final String title;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDarkMode
              ? AppColors.darkTextSecondary
              : const Color(0xFF717783),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

