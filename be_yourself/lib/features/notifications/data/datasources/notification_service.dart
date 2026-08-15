import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:be_yourself/features/home_widget/services/home_widget_service.dart';
import 'package:be_yourself/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';
import 'package:be_yourself/features/quote/presentation/pages/quote_detail_page.dart';
import 'package:be_yourself/main.dart';
import 'package:be_yourself/shared/widgets/main_shell_page.dart';

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
      'author': 'Günün Alıntısı 💫',
    },
    {
      'text': 'Her yeni gün, yepyeni bir başlangıç ve fırsattır.',
      'author': 'Günün Alıntısı 💫',
    },
    {
      'text': 'Zorluklar, seni daha güçlü kılmak için vardır.',
      'author': 'Günün Alıntısı 💫',
    },
    {
      'text': 'Bugün kendin için güzel bir adım at.',
      'author': 'Günün Alıntısı 💫',
    },
    {
      'text': 'Küçük adımlar, büyük zaferlerin anahtarıdır.',
      'author': 'Günün Alıntısı 💫',
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
        handleNotificationClick(response.payload);
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

  static String getDailySentKey(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'daily_sent_notification_quote_ids_${y}_${m}_$d';
  }

  Future<List<String>> getSentQuoteIdsForDate(
    DateTime date, {
    SharedPreferences? prefs,
  }) async {
    final sp = prefs ?? await SharedPreferences.getInstance();
    return sp.getStringList(getDailySentKey(date)) ?? [];
  }

  Future<void> recordSentQuoteIds(
    List<String> quoteIds, {
    DateTime? date,
    SharedPreferences? prefs,
  }) async {
    if (quoteIds.isEmpty) return;
    final targetDate = date ?? DateTime.now();
    final sp = prefs ?? await SharedPreferences.getInstance();
    final key = getDailySentKey(targetDate);
    final currentList = sp.getStringList(key) ?? [];
    final currentSet = currentList.toSet();
    bool changed = false;
    for (final id in quoteIds) {
      if (id.trim().isNotEmpty && currentSet.add(id.trim())) {
        currentList.add(id.trim());
        changed = true;
      }
    }
    if (changed) {
      await sp.setStringList(key, currentList);
    }
  }

  Future<void> handleNotificationClick(String? payload) async {
    if (payload == null || payload.trim().isEmpty) return;

    debugPrint('Navigating to quote detail for quoteId: $payload');

    // 1. Rotate widget to a different quote since this notification's quote is opened
    try {
      await HomeWidgetService.instance
          .rotateWidgetToDifferentQuote(excludeQuoteId: payload);
    } catch (e) {
      debugPrint('HomeWidget rotation on notification click error: $e');
    }

    // 2. Mark this quote as sent/viewed today
    try {
      await recordSentQuoteIds([payload]);
    } catch (e) {
      debugPrint('recordSentQuoteIds on notification click error: $e');
    }

    final navState = appNavigatorKey.currentState;
    if (navState == null) return;

    if (WelcomePage.isShowing) {
      WelcomePage.isShowing = false;
      navState.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShellPage()),
        (route) => false,
      );
    }

    navState.push(
      MaterialPageRoute(
        builder: (_) => QuoteDetailPage(quoteId: payload),
      ),
    );
  }

  Future<void> checkPendingNotificationLaunch() async {
    try {
      final details =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        final payload = details?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          handleNotificationClick(payload);
        }
      }
    } catch (e) {
      debugPrint('Error checking launch notification: $e');
    }
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

  List<Map<String, String>> pickDistinctQuotesForSlots({
    required int count,
    required List<Quote> quotes,
    required Set<String> sentTodayIds,
  }) {
    if (count <= 0) return [];

    final List<Map<String, String>> selectedQuotes = [];
    final Set<String> usedIdsToday = Set<String>.from(sentTodayIds);

    // 1. First, pick quotes from user's quotes that have NOT yet been sent/shown today
    final availableUserQuotes = quotes
        .where((q) => !usedIdsToday.contains(q.id))
        .toList();

    for (final userQuote in availableUserQuotes) {
      if (selectedQuotes.length >= count) break;
      selectedQuotes.add({
        'id': userQuote.id,
        'text': userQuote.displayText,
        'author': userQuote.author.isNotEmpty ? userQuote.author : 'Anonim',
      });
      usedIdsToday.add(userQuote.id);
    }

    // 2. If we still need more quotes and not enough unsent user quotes,
    // use unique fallback quotes so that no quote is repeated twice in the same day
    if (selectedQuotes.length < count) {
      for (int i = 0; i < _fallbackQuotes.length; i++) {
        if (selectedQuotes.length >= count) break;
        final fallbackId = 'fallback_$i';
        if (!usedIdsToday.contains(fallbackId)) {
          selectedQuotes.add({
            'id': fallbackId,
            'text': _fallbackQuotes[i]['text']!,
            'author': _fallbackQuotes[i]['author']!,
          });
          usedIdsToday.add(fallbackId);
        }
      }
    }

    // 3. Ultra-fallback if count exceeds fallback list too
    int fallbackIndex = 0;
    while (selectedQuotes.length < count) {
      final index = fallbackIndex % _fallbackQuotes.length;
      final fallbackId = 'fallback_extra_${selectedQuotes.length}';
      selectedQuotes.add({
        'id': fallbackId,
        'text': _fallbackQuotes[index]['text']!,
        'author': _fallbackQuotes[index]['author']!,
      });
      fallbackIndex++;
    }

    return selectedQuotes;
  }

  Future<void> scheduleDailyQuoteNotifications({
    required int count,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required List<Quote> quotes,
    SharedPreferences? prefs,
  }) async {
    await initialize();
    await cancelAll();

    if (count <= 0) return;

    final List<TimeOfDay> slots = _calculateTimeSlots(
      count: count,
      startTime: startTime,
      endTime: endTime,
    );

    final now = DateTime.now();
    final sentTodayList = await getSentQuoteIdsForDate(now, prefs: prefs);
    final sentTodaySet = sentTodayList.toSet();

    final slotQuotes = pickDistinctQuotesForSlots(
      count: slots.length,
      quotes: quotes,
      sentTodayIds: sentTodaySet,
    );

    final List<String> newlyScheduledIds = [];

    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final quote = slotQuotes[i];
      if (quote['id'] != null) {
        newlyScheduledIds.add(quote['id']!);
      }

      final scheduledTime = _nextInstanceOfTime(slot.hour, slot.minute);

      final quoteTitle = (quote['author'] != null &&
              quote['author']!.trim().isNotEmpty &&
              quote['author'] != 'Anonim')
          ? quote['author']!
          : 'Günün Alıntısı 💫';

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
          quote['text'] ?? '',
          contentTitle: quoteTitle,
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

      try {
        await _notificationsPlugin.zonedSchedule(
          i + 1, // ID (1..count)
          quoteTitle,
          quote['text'],
          scheduledTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: quote['id'],
        );
      } catch (e) {
        debugPrint(
            'Exact alarm zonedSchedule error: $e, falling back to inexact mode');
        try {
          await _notificationsPlugin.zonedSchedule(
            i + 1,
            quoteTitle,
            quote['text'],
            scheduledTime,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: quote['id'],
          );
        } catch (innerError) {
          debugPrint('Inexact zonedSchedule error: $innerError');
        }
      }
    }

    if (newlyScheduledIds.isNotEmpty) {
      await recordSentQuoteIds(newlyScheduledIds, date: now, prefs: prefs);
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
