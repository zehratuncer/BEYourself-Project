import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quote_reminder/main.dart';
import 'package:quote_reminder/features/quote/domain/entities/quote.dart';

class QuoteNotifier extends StateNotifier<List<Quote>> {
  QuoteNotifier()
      : super([
          Quote(
            id: '1',
            text:
                'Zorluklar, sıradan insanları sıra dışı bir kadere hazırlamak için doğanın kullandığı araçlardır.',
            author: 'C.S. Lewis',
            categoryName: 'Motivasyon',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            isFavorite: false,
          ),
          Quote(
            id: '2',
            text:
                'İçindeki sese güven, o genellikle ne yapman gerektiğini bilir, mantığın henüz bir açıklama bulamasa bile.',
            author: 'Bilinmeyen',
            categoryName: 'Psikoloji',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            isFavorite: false,
          ),
          Quote(
            id: '3',
            text:
                'Kendini bulmak, kendini yaratmakla aynı şey değildir. Kendini yaratmak, kim olmak istediğine karar verip o yönde adım atmaktır.',
            author: 'Thomas Szasz',
            categoryName: 'Motivasyon',
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
            isFavorite: true,
          ),
          Quote(
            id: '4',
            text:
                'Başarı, coşkuyu kaybetmeden başarısızlıktan başarısızlığa koşabilme yeteneğidir.',
            author: 'Winston Churchill',
            categoryName: 'Motivasyon',
            createdAt: DateTime.now().subtract(const Duration(days: 4)),
            isFavorite: false,
          ),
        ]);

  void toggleFavorite(String id) {
    state = [
      for (final quote in state)
        if (quote.id == id)
          quote.copyWith(isFavorite: !quote.isFavorite)
        else
          quote,
    ];
  }

  void addQuote(Quote quote) {
    state = [quote, ...state];
  }

  void updateQuote(Quote quote) {
    state = [
      for (final item in state)
        if (item.id == quote.id) quote else item,
    ];
  }

  void deleteQuote(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void renameCategory(String oldCategoryName, String newCategoryName) {
    state = [
      for (final quote in state)
        if (quote.categoryName == oldCategoryName)
          quote.copyWith(categoryName: newCategoryName)
        else
          quote,
    ];
  }

  void handleCategoryDeleted(String categoryName) {
    state = [
      for (final quote in state)
        if (quote.categoryName == categoryName)
          quote.copyWith(categoryName: 'Genel')
        else
          quote,
    ];
  }
}

final quoteListProvider =
    StateNotifierProvider<QuoteNotifier, List<Quote>>((ref) {
  return QuoteNotifier();
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
      return Quote(
        id: '0',
        text: 'Henüz söz eklenmedi.',
        author: 'Sistem',
        categoryName: 'Genel',
        createdAt: DateTime.now(),
      );
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
       });
    }

    return existingQuote;
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
