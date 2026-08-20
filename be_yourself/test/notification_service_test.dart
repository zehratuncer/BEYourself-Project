import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:be_yourself/features/notifications/data/datasources/notification_service.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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

    test('Schedule method updates payload and slots when quotes are deleted', () async {
      final service = NotificationService.instance;

      final initialQuotes = [
        Quote(
          id: 'q1',
          text: 'İlk Alıntı',
          author: 'Yazar 1',
          categoryName: 'Genel',
          createdAt: DateTime.now(),
        ),
        Quote(
          id: 'q2',
          text: 'İkinci Alıntı',
          author: 'Yazar 2',
          categoryName: 'Genel',
          createdAt: DateTime.now(),
        ),
      ];

      // Schedule with 2 quotes
      await service.scheduleDailyQuoteNotifications(
        count: 2,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 0),
        quotes: initialQuotes,
      );

      // Simulate deleting 'q1' -> only 'q2' remains
      final updatedQuotes = initialQuotes.where((q) => q.id != 'q1').toList();

      await service.scheduleDailyQuoteNotifications(
        count: 2,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 0),
        quotes: updatedQuotes,
      );

      expect(updatedQuotes.length, 1);
      expect(updatedQuotes.first.id, 'q2');
    });

    test('pickDistinctQuotesForSlots picks unique quotes across slots and excludes already sent today or yesterday', () {
      final service = NotificationService.instance;

      final testQuotes = [
        Quote(
          id: 'quote_1',
          text: 'Alıntı 1',
          author: 'Yazar 1',
          categoryName: 'Genel',
          createdAt: DateTime.now(),
        ),
        Quote(
          id: 'quote_2',
          text: 'Alıntı 2',
          author: 'Yazar 2',
          categoryName: 'Genel',
          createdAt: DateTime.now(),
        ),
        Quote(
          id: 'quote_3',
          text: 'Alıntı 3',
          author: 'Yazar 3',
          categoryName: 'Genel',
          createdAt: DateTime.now(),
        ),
      ];

      // Case 1: Slot count = 3, no prior sent quotes -> all 3 should be unique
      final slots1 = service.pickDistinctQuotesForSlots(
        count: 3,
        quotes: testQuotes,
        sentTodayIds: {},
      );
      expect(slots1.length, 3);
      final ids1 = slots1.map((s) => s['id']).toSet();
      expect(ids1.length, 3);
      expect(ids1.contains('quote_1'), true);
      expect(ids1.contains('quote_2'), true);
      expect(ids1.contains('quote_3'), true);

      // Case 2: quote_1 was sent today, quote_2 was sent yesterday -> only quote_3 is available
      final slots2 = service.pickDistinctQuotesForSlots(
        count: 2,
        quotes: testQuotes,
        sentTodayIds: {'quote_1'},
        sentYesterdayIds: {'quote_2'},
      );
      expect(slots2.length, 1);
      expect(slots2.first['id'], 'quote_3');

      // Case 3: All 3 user quotes were already sent today/yesterday, count is 2 -> NO mock notifications should be returned
      final slots3 = service.pickDistinctQuotesForSlots(
        count: 2,
        quotes: testQuotes,
        sentTodayIds: {'quote_1', 'quote_2'},
        sentYesterdayIds: {'quote_3'},
      );
      expect(slots3, isEmpty, reason: 'Must not send mock notifications when no eligible quotes remain');
    });

    test('recordSentQuoteIds and getSentQuoteIdsForDate persist unique quote IDs per day', () async {
      final service = NotificationService.instance;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final today = DateTime.now();
      expect(await service.getSentQuoteIdsForDate(today, prefs: prefs), isEmpty);

      await service.recordSentQuoteIds(['quote_a', 'quote_b'], date: today, prefs: prefs);
      final recorded = await service.getSentQuoteIdsForDate(today, prefs: prefs);
      expect(recorded, ['quote_a', 'quote_b']);

      // Adding duplicate should not duplicate entries
      await service.recordSentQuoteIds(['quote_b', 'quote_c'], date: today, prefs: prefs);
      final updated = await service.getSentQuoteIdsForDate(today, prefs: prefs);
      expect(updated, ['quote_a', 'quote_b', 'quote_c']);
    });
  });
}
