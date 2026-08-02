import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quote_reminder/core/theme/app_colors.dart';
import 'package:quote_reminder/features/notifications/presentation/pages/notification_settings_page.dart';

final isDarkModeProvider = StateProvider<bool>((ref) => false);
final dailyNotificationEnabledProvider = StateProvider<bool>((ref) => true);

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final dailyNotifications = ref.watch(dailyNotificationEnabledProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            const Text(
              'Ayarlar',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),

            // Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF60A5FA).withAlpha(15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBlue.withAlpha(25),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primaryBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Can Yılmaz',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111C2D),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Offline Kullanıcı',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF516072),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const _SectionHeader(title: 'BİLDİRİM VE TEMA'),

            // Notification & Theme section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF60A5FA).withAlpha(15),
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
                      title: const Text('Günlük Bildirimler'),
                      subtitle: const Text('Günün ilham veren sözlerini al'),
                      value: dailyNotifications,
                      activeThumbColor: AppColors.primaryBlue,
                      onChanged: (val) {
                        ref
                            .read(dailyNotificationEnabledProvider.notifier)
                            .state = val;
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.notifications_active_outlined,
                          color: AppColors.primaryBlue),
                      title: const Text('Bildirim Tercihleri'),
                      subtitle: const Text('Saat ve kategori aralığını ayarla'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsPage(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: const Text('Karanlık Mod'),
                      subtitle: const Text('Gece gözlerinizi yormayan görünüm'),
                      value: isDarkMode,
                      activeThumbColor: AppColors.primaryBlue,
                      onChanged: (val) {
                        ref.read(isDarkModeProvider.notifier).state = val;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),
            const _SectionHeader(title: 'UYGULAMA BİLGİLERİ'),

            // App info section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF60A5FA).withAlpha(15),
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
                    const ListTile(
                      leading: Icon(Icons.info_outline,
                          color: AppColors.primaryBlue),
                      title: Text('Sürüm'),
                      trailing: Text(
                        'v1.0.0 (Offline)',
                        style: TextStyle(color: Color(0xFF516072)),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.share_outlined,
                          color: AppColors.primaryBlue),
                      title: const Text('Uygulamayı Paylaş'),
                      onTap: () {},
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
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF717783),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
