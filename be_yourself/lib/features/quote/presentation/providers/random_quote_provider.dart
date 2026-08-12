import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';

class RandomQuoteState {
  final Quote? currentQuote;
  final String selectedCategory;
  final List<String> recentQuoteIds;
  final bool isRolling;
  final int rollCount;
  final bool isEmpty;

  const RandomQuoteState({
    this.currentQuote,
    this.selectedCategory = 'Hepsi',
    this.recentQuoteIds = const [],
    this.isRolling = false,
    this.rollCount = 0,
    this.isEmpty = false,
  });

  RandomQuoteState copyWith({
    Quote? Function()? currentQuote,
    String? selectedCategory,
    List<String>? recentQuoteIds,
    bool? isRolling,
    int? rollCount,
    bool? isEmpty,
  }) {
    return RandomQuoteState(
      currentQuote: currentQuote != null ? currentQuote() : this.currentQuote,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      recentQuoteIds: recentQuoteIds ?? this.recentQuoteIds,
      isRolling: isRolling ?? this.isRolling,
      rollCount: rollCount ?? this.rollCount,
      isEmpty: isEmpty ?? this.isEmpty,
    );
  }
}

class RandomQuoteNotifier extends StateNotifier<RandomQuoteState> {
  RandomQuoteNotifier() : super(const RandomQuoteState());

  static const int maxHistoryLength = 5;
  final Random _random = Random();

  /// Rolls a random quote from the provided quotes list, taking category filter and history into account.
  void rollQuote(List<Quote> quotes, {String? category}) {
    final activeCategory = category ?? state.selectedCategory;

    final pool = quotes.where((q) {
      if (activeCategory == 'Hepsi') return true;
      return q.categoryName.toLowerCase() == activeCategory.toLowerCase();
    }).toList();

    if (pool.isEmpty) {
      state = state.copyWith(
        currentQuote: () => null,
        selectedCategory: activeCategory,
        isEmpty: true,
        isRolling: false,
        rollCount: state.rollCount + 1,
      );
      return;
    }

    if (pool.length == 1) {
      state = state.copyWith(
        currentQuote: () => pool.first,
        selectedCategory: activeCategory,
        recentQuoteIds: [pool.first.id],
        isEmpty: false,
        isRolling: false,
        rollCount: state.rollCount + 1,
      );
      return;
    }

    // Filter out recently shown quote IDs to avoid consecutive duplicates
    var available = pool
        .where((q) => !state.recentQuoteIds.contains(q.id))
        .toList();

    // If all quotes in the pool have been shown recently, allow all except the very last one
    if (available.isEmpty) {
      final lastId = state.recentQuoteIds.isNotEmpty
          ? state.recentQuoteIds.last
          : null;
      available = pool.where((q) => q.id != lastId).toList();
      if (available.isEmpty) {
        available = pool;
      }
    }

    final picked = available[_random.nextInt(available.length)];

    final updatedHistory = [
      ...state.recentQuoteIds,
      picked.id,
    ];
    if (updatedHistory.length > maxHistoryLength) {
      updatedHistory.removeAt(0);
    }

    state = state.copyWith(
      currentQuote: () => picked,
      selectedCategory: activeCategory,
      recentQuoteIds: updatedHistory,
      isEmpty: false,
      isRolling: false,
      rollCount: state.rollCount + 1,
    );
  }

  void setCategory(String category, List<Quote> quotes) {
    rollQuote(quotes, category: category);
  }

  void setRolling(bool isRolling) {
    state = state.copyWith(isRolling: isRolling);
  }
}

final randomQuoteNotifierProvider =
    StateNotifierProvider<RandomQuoteNotifier, RandomQuoteState>((ref) {
  return RandomQuoteNotifier();
});
