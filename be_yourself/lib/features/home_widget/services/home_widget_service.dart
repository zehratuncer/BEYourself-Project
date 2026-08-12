import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'package:be_yourself/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';
import 'package:be_yourself/features/quote/presentation/pages/quote_detail_page.dart';
import 'package:be_yourself/main.dart';
import 'package:be_yourself/shared/widgets/main_shell_page.dart';

class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  static const String appGroupId = 'group.com.example.be_yourself';
  static const String androidWidgetName = 'QuoteWidgetProvider';
  static const String iOSWidgetName = 'BeYourselfWidget';

  StreamSubscription<Uri?>? _widgetClickSubscription;

  /// Initializes AppGroup and registers deep link listeners for widget clicks.
  Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('HomeWidget setAppGroupId error: $e');
    }

    _widgetClickSubscription?.cancel();
    _widgetClickSubscription = HomeWidget.widgetClicked.listen((Uri? uri) {
      if (uri != null) {
        handleWidgetUri(uri);
      }
    });
  }

  /// Checks if the app was initially launched by tapping on a home screen widget.
  Future<void> checkPendingWidgetLaunch() async {
    try {
      final launchUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (launchUri != null) {
        handleWidgetUri(launchUri);
      }
    } catch (e) {
      debugPrint('HomeWidget checkPendingWidgetLaunch error: $e');
    }
  }

  static final Quote defaultFallbackQuote = Quote(
    id: 'default_fallback',
    text: 'Kendine inan, yapabileceklerinin sınırı yoktur.',
    author: 'BeYourself 💫',
    categoryName: 'Genel',
    createdAt: DateTime.now(),
  );

  /// Clears or updates widget with fallback quote when no quotes exist
  Future<void> updateWidgetWithFallback() async {
    await updateQuoteWidget(defaultFallbackQuote);
  }

  /// Updates the native home screen widget with the latest quote data.
  Future<void> updateQuoteWidget(Quote quote) async {
    try {
      await HomeWidget.saveWidgetData<String>('quote_id', quote.id);
      await HomeWidget.saveWidgetData<String>('quote_text', quote.displayText);
      await HomeWidget.saveWidgetData<String>('quote_author', quote.author);
      await HomeWidget.saveWidgetData<String>('quote_category', quote.categoryName);

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      debugPrint('HomeWidget updateQuoteWidget error: $e');
    }
  }

  /// Handles deep link Uri triggered by widget tap (e.g., beyourself://quote?id=123)
  void handleWidgetUri(Uri uri) {
    final quoteId = uri.queryParameters['id'] ?? (uri.host == 'quote' ? uri.pathSegments.firstOrNull : null) ?? '';
    
    if (quoteId.isNotEmpty) {
      final navState = appNavigatorKey.currentState;
      if (navState != null) {
        if (WelcomePage.isShowing) {
          WelcomePage.isShowing = false;
          navState.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainShellPage()),
            (route) => false,
          );
        }
        navState.push(
          MaterialPageRoute(
            builder: (_) => QuoteDetailPage(quoteId: quoteId),
          ),
        );
      }
    }
  }

  void dispose() {
    _widgetClickSubscription?.cancel();
  }
}
