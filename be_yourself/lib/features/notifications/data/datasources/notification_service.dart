import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:be_yourself/features/quote/domain/entities/quote.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'beyourself_quotes_channel_v1';
  static const String channelName = 'Günün Alıntıları';
  static const String channelDescription =
      'BeYourself günün ilham verici alıntı ve hatırlatıcı bildirimleri';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  static const List<Map<String, String>> _fallbackQuotes = [
    {
      'text': 'Kendine inan, yapabileceklerinin sınırı yoktur.',
      'author': 'BeYourself',
    },
    {
      'text': 'Her yeni gün, yepyeni bir başlangıç ve fırsattır.',
      'author': 'BeYourself',
    },
    {
      'text': 'Zorluklar, seni daha güçlü kılmak için vardır.',
      'author': 'BeYourself',
    },
    {
      'text': 'Bugün kendin için güzel bir adım at.',
      'author': 'BeYourself',
    },
    {
      'text': 'Küçük adımlar, büyük zaferlerin anahtarıdır.',
      'author': 'BeYourself',
    },
  ];

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz_data.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezones init error: $e');
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked with payload: ${response.payload}');
      },
    );

    // Explicitly create notification channel on Android
    if (!kIsWeb && Platform.isAndroid) {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        await androidImplementation.createNotificationChannel(channel);
      }
    }

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted =
            await androidImplementation.requestNotificationsPermission();
        final areEnabled =
            await androidImplementation.areNotificationsEnabled();
        return (granted ?? false) || (areEnabled ?? false);
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      final iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/launcher_icon',
      showWhen: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'BeYourself',
      ),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final id = Random().nextInt(100000);
    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> scheduleDailyQuoteNotifications({
    required int count,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required List<Quote> quotes,
  }) async {
    await initialize();
    await cancelAll();

    if (count <= 0) return;

    final List<TimeOfDay> slots = _calculateTimeSlots(
      count: count,
      startTime: startTime,
      endTime: endTime,
    );

    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final quote = _pickQuoteForSlot(i, quotes);

      final scheduledTime = _nextInstanceOfTime(slot.hour, slot.minute);

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          quote['text'] ?? '',
          contentTitle: 'BeYourself • ${quote['author']}',
          summaryText: 'Günün İlhamı',
        ),
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        i + 1, // ID (1..count)
        'BeYourself • ${quote['author']}',
        quote['text'],
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: quote['id'],
      );
    }
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  List<TimeOfDay> _calculateTimeSlots({
    required int count,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) {
    if (count <= 1) {
      return [startTime];
    }

    final int startMins = startTime.hour * 60 + startTime.minute;
    int endMins = endTime.hour * 60 + endTime.minute;

    if (endMins <= startMins) {
      endMins += 24 * 60;
    }

    final double step = (endMins - startMins) / (count - 1);
    final List<TimeOfDay> slots = [];

    for (int i = 0; i < count; i++) {
      final int currentMins = (startMins + (step * i).round()) % (24 * 60);
      slots.add(
        TimeOfDay(
          hour: currentMins ~/ 60,
          minute: currentMins % 60,
        ),
      );
    }

    return slots;
  }

  Map<String, String> _pickQuoteForSlot(int index, List<Quote> quotes) {
    if (quotes.isNotEmpty) {
      final selected = quotes[index % quotes.length];
      return {
        'id': selected.id,
        'text': selected.displayText,
        'author': selected.author.isNotEmpty ? selected.author : 'Anonim',
      };
    }

    final fallback = _fallbackQuotes[index % _fallbackQuotes.length];
    return {
      'id': 'fallback_$index',
      'text': fallback['text']!,
      'author': fallback['author']!,
    };
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.Location location = tz.local;
    final tz.TZDateTime now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
