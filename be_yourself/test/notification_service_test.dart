import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:be_yourself/features/notifications/data/datasources/notification_service.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'initialize') {
          return true;
        }
        if (methodCall.method == 'zonedSchedule' ||
            methodCall.method == 'cancelAll' ||
            methodCall.method == 'show') {
          return null;
        }
        if (methodCall.method == 'requestNotificationsPermission' ||
            methodCall.method == 'requestPermissions') {
          return true;
        }
        if (methodCall.method == 'getNotificationAppLaunchDetails') {
          return null;
        }
        return null;
      },
    );
  });

  group('NotificationService Tests', () {
    test('NotificationService singleton instance check', () {
      final s1 = NotificationService.instance;
      final s2 = NotificationService.instance;
      expect(identical(s1, s2), true);
    });

    test('Schedule method runs without errors with empty and non-empty quotes', () async {
      final service = NotificationService.instance;

      // With empty quotes (uses fallbacks)
      await service.scheduleDailyQuoteNotifications(
        count: 3,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 21, minute: 0),
        quotes: [],
      );

      // With actual quotes
      final testQuotes = [
        Quote(
          id: '1',
          text: 'Güzel bir gün.',
          author: 'Yazar 1',
          categoryName: 'Genel',
          createdAt: DateTime.now(),
        ),
        Quote(
          id: '2',
          text: 'Başarı yolculuktur.',
          author: 'Yazar 2',
          categoryName: 'Motivasyon',
          createdAt: DateTime.now(),
        ),
      ];

      await service.scheduleDailyQuoteNotifications(
        count: 5,
        startTime: const TimeOfDay(hour: 8, minute: 30),
        endTime: const TimeOfDay(hour: 22, minute: 0),
        quotes: testQuotes,
      );

      await service.showInstantNotification(
        title: 'Günün Alıntısı 💫',
        body: 'Test İçerik',
        payload: '1',
      );

      await service.checkPendingNotificationLaunch();
      await service.cancelAll();
    });
  });
}
