import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:be_yourself/features/home_widget/services/home_widget_service.dart';
import 'package:be_yourself/features/quote/data/datasources/quote_local_datasource.dart';
import 'package:be_yourself/features/quote/data/datasources/quote_remote_data_source.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';
import 'package:be_yourself/main.dart';

class QuoteNotifier extends StateNotifier<List<Quote>> {
  final QuoteLocalDataSource _dataSource;
  final QuoteRemoteDataSource remoteDataSource;
  final String deviceId;

  QuoteNotifier(
    this._dataSource, {
    this.remoteDataSource = const QuoteRemoteDataSource(),
    this.deviceId = '',
  }) : super([]) {
    _loadQuotes();
    _syncWithRemote();
  }

  void _loadQuotes() {
    state = _dataSource.getQuotes();
  }

  Future<void> _syncWithRemote() async {
    if (deviceId.isEmpty) return;
    try {
      final remoteQuotes = await remoteDataSource.getQuotes(deviceId);
      if (remoteQuotes.isNotEmpty) {
        final localMap = {for (final q in state) q.id: q};
        for (final rq in remoteQuotes) {
          localMap[rq.id] = rq;
        }
        state = localMap.values.toList();
        _persist();
      } else if (state.isNotEmpty) {
        for (final localQuote in state) {
          remoteDataSource.upsertQuote(localQuote, deviceId);
        }
      }
    } catch (_) {}
  }

  void _persist() {
    _dataSource.saveQuotes(state);
  }

  void toggleFavorite(String id) {
    state = [
      for (final quote in state)
        if (quote.id == id)
          quote.copyWith(isFavorite: !quote.isFavorite)
        else
          quote,
    ];
    _persist();
    if (deviceId.isNotEmpty) {
      final updated = state.firstWhere((q) => q.id == id);
      remoteDataSource.upsertQuote(updated, deviceId);
    }
  }

  void addQuote(Quote quote) {
    state = [quote, ...state];
    _persist();
    if (deviceId.isNotEmpty) {
      remoteDataSource.upsertQuote(quote, deviceId);
    }
  }

  void updateQuote(Quote quote) {
    state = [
      for (final item in state)
        if (item.id == quote.id) quote else item,
    ];
    _persist();
    if (deviceId.isNotEmpty) {
      remoteDataSource.upsertQuote(quote, deviceId);
    }
    const quoteIdKey = 'quoteOfDay_id';
    final savedId = _dataSource.prefs.getString(quoteIdKey);
    if (savedId == quote.id) {
      HomeWidgetService.instance.updateQuoteWidget(quote);
    }
  }

  void deleteQuote(String id) {
    state = state.where((item) => item.id != id).toList();
    _persist();
    if (deviceId.isNotEmpty) {
      remoteDataSource.deleteQuote(id, deviceId);
    }
    _syncWidgetAfterDelete(id);
  }

  void clearAllQuotes() {
    state = [];
    _persist();
    if (deviceId.isNotEmpty) {
      remoteDataSource.clearAllQuotes(deviceId);
    }
    _dataSource.prefs.remove('quoteOfDay_id');
    _dataSource.prefs.remove('quoteOfDay_time');
    HomeWidgetService.instance.updateWidgetWithFallback();
  }

  void _syncWidgetAfterDelete(String deletedId) {
    const quoteIdKey = 'quoteOfDay_id';
    const quoteTimeKey = 'quoteOfDay_time';
    final savedId = _dataSource.prefs.getString(quoteIdKey);

    if (savedId == deletedId) {
      _dataSource.prefs.remove(quoteIdKey);
      _dataSource.prefs.remove(quoteTimeKey);

      if (state.isNotEmpty) {
        final random = Random();
        final newQuote = state[random.nextInt(state.length)];
        _dataSource.prefs.setString(quoteIdKey, newQuote.id);
        _dataSource.prefs.setString(
            quoteTimeKey, DateTime.now().toIso8601String());
        HomeWidgetService.instance.updateQuoteWidget(newQuote);
      } else {
        HomeWidgetService.instance.updateWidgetWithFallback();
      }
    }
  }

  void renameCategory(String oldCategoryName, String newCategoryName) {
    state = [
      for (final quote in state)
        if (quote.categoryName == oldCategoryName)
          quote.copyWith(categoryName: newCategoryName)
        else
          quote,
    ];
    _persist();
  }

  void handleCategoryDeleted(String categoryName) {
    state = [
      for (final quote in state)
        if (quote.categoryName == categoryName)
          quote.copyWith(categoryName: 'Genel')
        else
          quote,
    ];
    _persist();
  }
}

final quoteLocalDataSourceProvider = Provider<QuoteLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return QuoteLocalDataSource(prefs);
});

final quoteRemoteDataSourceProvider = Provider<QuoteRemoteDataSource>((ref) {
  return const QuoteRemoteDataSource();
});

final quoteListProvider =
    StateNotifierProvider<QuoteNotifier, List<Quote>>((ref) {
  final dataSource = ref.watch(quoteLocalDataSourceProvider);
  final remoteDataSource = ref.watch(quoteRemoteDataSourceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final deviceId = prefs.getString('user_device_private_uuid') ?? '';
  return QuoteNotifier(
    dataSource,
    remoteDataSource: remoteDataSource,
    deviceId: deviceId,
  );
});

final selectedCategoryFilterProvider = StateProvider<String>((ref) => 'Hepsi');

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredQuoteListProvider = Provider<List<Quote>>((ref) {
  final quotes = ref.watch(quoteListProvider);
  final category = ref.watch(selectedCategoryFilterProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return quotes.where((quote) {
    final matchesCategory =
        category == 'Hepsi' || quote.categoryName == category;
    final matchesQuery = query.isEmpty ||
        quote.text.toLowerCase().contains(query) ||
        quote.author.toLowerCase().contains(query);
    return matchesCategory && matchesQuery;
  }).toList();
});

final favoriteQuoteListProvider = Provider<List<Quote>>((ref) {
  final quotes = ref.watch(quoteListProvider);
  return quotes.where((quote) => quote.isFavorite).toList();
});

class QuoteOfDayState {
  final Quote quote;
  final DateTime selectedAt;

  const QuoteOfDayState({
    required this.quote,
    required this.selectedAt,
  });
}

class QuoteOfDayNotifier extends StateNotifier<QuoteOfDayState?> {
  final SharedPreferences prefs;

  QuoteOfDayNotifier(this.prefs) : super(null) {
    _loadFromPrefs();
  }

  static const _quoteIdKey = 'quoteOfDay_id';
  static const _quoteTimeKey = 'quoteOfDay_time';

  void _loadFromPrefs() {
    final savedId = prefs.getString(_quoteIdKey);
    final savedTimeStr = prefs.getString(_quoteTimeKey);
    if (savedId != null && savedTimeStr != null) {
      final savedTime = DateTime.tryParse(savedTimeStr);
      if (savedTime != null) {
        // We set a temporary state without the full quote just to know the time.
        // It will be resolved in getOrUpdateQuoteOfDay
      }
    }
  }

  Quote getOrUpdateQuoteOfDay(List<Quote> quotes) {
    if (quotes.isEmpty) {
      final fallback = HomeWidgetService.defaultFallbackQuote;
      prefs.remove(_quoteIdKey);
      prefs.remove(_quoteTimeKey);
      if (state?.quote.id != fallback.id) {
        Future.microtask(() {
          state = QuoteOfDayState(quote: fallback, selectedAt: DateTime.now());
          HomeWidgetService.instance.updateWidgetWithFallback();
        });
      }
      return fallback;
    }

    final now = DateTime.now();
    final savedId = prefs.getString(_quoteIdKey);
    final savedTimeStr = prefs.getString(_quoteTimeKey);

    DateTime? lastSelectedAt;
    if (savedTimeStr != null) {
      lastSelectedAt = DateTime.tryParse(savedTimeStr);
    }

    // Determine if we need to pick a new quote
    bool needsNewQuote = false;
    if (savedId == null || lastSelectedAt == null) {
      needsNewQuote = true;
    } else if (now.difference(lastSelectedAt).inHours >= 4) {
      needsNewQuote = true;
    } else {
      // Check if saved quote still exists
      if (!quotes.any((q) => q.id == savedId)) {
        needsNewQuote = true;
      }
    }

    if (needsNewQuote) {
      final random = Random();
      final newQuote = quotes[random.nextInt(quotes.length)];
      
      // Save to SharedPreferences
      prefs.setString(_quoteIdKey, newQuote.id);
      prefs.setString(_quoteTimeKey, now.toIso8601String());

      // Only update state if it actually changes (to prevent unnecessary rebuilds)
      if (state?.quote.id != newQuote.id || state?.selectedAt != now) {
        // Schedule state update after build frame
        Future.microtask(() {
          state = QuoteOfDayState(quote: newQuote, selectedAt: now);
          HomeWidgetService.instance.updateQuoteWidget(newQuote);
        });
      }
      return newQuote;
    }

    // Return the cached quote based on savedId
    final existingQuote = quotes.firstWhere(
      (q) => q.id == savedId,
      orElse: () => quotes.first, // fallback
    );

    if (state?.quote.id != existingQuote.id) {
       Future.microtask(() {
         state = QuoteOfDayState(quote: existingQuote, selectedAt: lastSelectedAt!);
         HomeWidgetService.instance.updateQuoteWidget(existingQuote);
       });
    }

    return existingQuote;
  }

  Quote rotateToDifferentQuote({
    required String excludeQuoteId,
    required List<Quote> quotes,
  }) {
    final candidateQuotes =
        quotes.where((q) => q.id != excludeQuoteId).toList();
    final now = DateTime.now();

    final Quote nextQuote;
    if (candidateQuotes.isNotEmpty) {
      final random = Random();
      nextQuote = candidateQuotes[random.nextInt(candidateQuotes.length)];
    } else if (quotes.isNotEmpty) {
      nextQuote = quotes.first;
    } else {
      nextQuote = HomeWidgetService.defaultFallbackQuote;
    }

    prefs.setString(_quoteIdKey, nextQuote.id);
    prefs.setString(_quoteTimeKey, now.toIso8601String());

    state = QuoteOfDayState(quote: nextQuote, selectedAt: now);
    HomeWidgetService.instance.updateQuoteWidget(nextQuote);
    return nextQuote;
  }
}

final quoteOfDayNotifierProvider =
    StateNotifierProvider<QuoteOfDayNotifier, QuoteOfDayState?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return QuoteOfDayNotifier(prefs);
});

final quoteOfDayProvider = Provider<Quote>((ref) {
  final quotes = ref.watch(quoteListProvider);
  return ref
      .watch(quoteOfDayNotifierProvider.notifier)
      .getOrUpdateQuoteOfDay(quotes);
});
