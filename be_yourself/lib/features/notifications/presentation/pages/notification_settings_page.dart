import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quote_reminder/core/theme/app_colors.dart';

final notificationCountProvider = StateProvider<int>((ref) => 3);
final notificationStartTimeProvider = StateProvider<TimeOfDay>(
  (ref) => const TimeOfDay(hour: 9, minute: 0),
);
final notificationEndTimeProvider = StateProvider<TimeOfDay>(
  (ref) => const TimeOfDay(hour: 21, minute: 0),
);

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificationCountProvider);
    final startTime = ref.watch(notificationStartTimeProvider);
    final endTime = ref.watch(notificationEndTimeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        title: const Text(
          'Bildirim Ayarları',
          style: TextStyle(
            color: Color(0xFF111C2D),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryBlue),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Günlük Hatırlatıcılar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gün içinde kaç bildirim almak istediğinizi ve saat aralığını seçin.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF516072),
              ),
            ),
            const SizedBox(height: 24),

            // Daily Count Card
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Günlük Bildirim Sıklığı',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111C2D),
                        ),
                      ),
                      Text(
                        '$count Adet',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
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
                    activeColor: AppColors.primaryBlue,
                    onChanged: (val) {
                      ref.read(notificationCountProvider.notifier).state =
                          val.toInt();
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
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Başlangıç Saati'),
                    trailing: Text(
                      startTime.format(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
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
                            .state = picked;
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Bitiş Saati'),
                    trailing: Text(
                      endTime.format(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (picked != null) {
                        ref.read(notificationEndTimeProvider.notifier).state =
                            picked;
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
