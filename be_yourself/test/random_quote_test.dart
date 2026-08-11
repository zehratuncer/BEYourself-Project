import 'package:flutter_test/flutter_test.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';
import 'package:be_yourself/features/quote/presentation/providers/random_quote_provider.dart';

void main() {
  group('RandomQuoteNotifier Tests', () {
    late RandomQuoteNotifier notifier;

    final mockQuotes = [
      Quote(
        id: '1',
        text: 'Hayat cesurları sever.',
        author: 'Anonim',
        categoryName: 'Motivasyon',
        createdAt: DateTime.now(),
      ),
      Quote(
        id: '2',
        text: 'Düşünüyorum, öyleyse varım.',
        author: 'Descartes',
        categoryName: 'Felsefe',
        createdAt: DateTime.now(),
      ),
      Quote(
        id: '3',
        text: 'Gülümsemek en güzel eylemdir.',
        author: 'Anonim',
        categoryName: 'Motivasyon',
        createdAt: DateTime.now(),
      ),
      Quote(
        id: '4',
        text: 'Bir kitap bir dünyadır.',
        author: 'Anonim',
        categoryName: 'Kitap',
        createdAt: DateTime.now(),
      ),
    ];

    setUp(() {
      notifier = RandomQuoteNotifier();
    });

    test('Initial state should be default empty values', () {
      expect(notifier.state.currentQuote, isNull);
      expect(notifier.state.selectedCategory, 'Hepsi');
      expect(notifier.state.isEmpty, isFalse);
      expect(notifier.state.recentQuoteIds, isEmpty);
      expect(notifier.state.rollCount, 0);
    });

    test('rollQuote should pick a quote from the pool and record its id in history', () {
      notifier.rollQuote(mockQuotes);

      expect(notifier.state.currentQuote, isNotNull);
      expect(notifier.state.isEmpty, isFalse);
      expect(notifier.state.recentQuoteIds, contains(notifier.state.currentQuote!.id));
      expect(notifier.state.rollCount, 1);
    });

    test('rollQuote with category filter should only pick quotes from that category', () {
      for (int i = 0; i < 10; i++) {
        notifier.rollQuote(mockQuotes, category: 'Kitap');
        expect(notifier.state.currentQuote, isNotNull);
        expect(notifier.state.currentQuote!.categoryName, 'Kitap');
        expect(notifier.state.currentQuote!.id, '4');
      }
    });

    test('rollQuote with empty pool should set isEmpty to true and currentQuote to null', () {
      notifier.rollQuote([], category: 'Hepsi');

      expect(notifier.state.currentQuote, isNull);
      expect(notifier.state.isEmpty, isTrue);
    });

    test('rollQuote with non-existent category should handle empty gracefully', () {
      notifier.rollQuote(mockQuotes, category: 'BilinmeyenKategori');

      expect(notifier.state.currentQuote, isNull);
      expect(notifier.state.isEmpty, isTrue);
    });

    test('History buffer prevents consecutive identical rolls when multiple candidates exist', () {
      final twoQuotes = [mockQuotes[0], mockQuotes[1]];
      
      notifier.rollQuote(twoQuotes);
      final firstId = notifier.state.currentQuote!.id;

      notifier.rollQuote(twoQuotes);
      final secondId = notifier.state.currentQuote!.id;

      // When there are 2 quotes, rolling a second time should pick the other one
      expect(secondId, isNot(equals(firstId)));
    });

    test('History buffer caps at maximum length (5)', () {
      final manyQuotes = List.generate(
        10,
        (i) => Quote(
          id: 'quote_$i',
          text: 'Quote $i',
          author: 'Author $i',
          categoryName: 'Genel',
          createdAt: DateTime.now(),
        ),
      );

      for (int i = 0; i < 10; i++) {
        notifier.rollQuote(manyQuotes);
      }

      expect(notifier.state.recentQuoteIds.length, lessThanOrEqualTo(RandomQuoteNotifier.maxHistoryLength));
    });
  });
}
