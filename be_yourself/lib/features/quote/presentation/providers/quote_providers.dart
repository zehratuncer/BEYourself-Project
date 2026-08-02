import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  QuoteOfDayNotifier() : super(null);

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

    // 4 saat geçip geçmediğini veya henüz seçim yapılmadığını kontrol et
    if (state == null ||
        now.difference(state!.selectedAt).inHours >= 4 ||
        !quotes.any((q) => q.id == state!.quote.id)) {
      final random = Random();
      final newQuote = quotes[random.nextInt(quotes.length)];
      state = QuoteOfDayState(quote: newQuote, selectedAt: now);
      return newQuote;
    }

    return state!.quote;
  }
}

final quoteOfDayNotifierProvider =
    StateNotifierProvider<QuoteOfDayNotifier, QuoteOfDayState?>((ref) {
  return QuoteOfDayNotifier();
});

final quoteOfDayProvider = Provider<Quote>((ref) {
  final quotes = ref.watch(quoteListProvider);
  return ref
      .watch(quoteOfDayNotifierProvider.notifier)
      .getOrUpdateQuoteOfDay(quotes);
});
