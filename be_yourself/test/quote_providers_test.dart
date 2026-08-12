import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:be_yourself/features/home_widget/services/home_widget_service.dart';
import 'package:be_yourself/features/quote/data/datasources/quote_local_datasource.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';
import 'package:be_yourself/features/quote/presentation/providers/quote_providers.dart';
import 'package:be_yourself/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuoteNotifier Advanced Business Logic Tests', () {
    late SharedPreferences prefs;
    late QuoteLocalDataSource dataSource;
    late QuoteNotifier notifier;

    final sampleQuote1 = Quote(
      id: 'q-1',
      text: 'Hayat cesurları sever.',
      author: 'Anonim',
      categoryName: 'Motivasyon',
      createdAt: DateTime(2026, 1, 1),
      isFavorite: false,
    );

    final sampleQuote2 = Quote(
      id: 'q-2',
      text: 'Düşünüyorum, öyleyse varım.',
      author: 'Descartes',
      categoryName: 'Felsefe',
      createdAt: DateTime(2026, 1, 2),
      isFavorite: true,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      dataSource = QuoteLocalDataSource(prefs);
      notifier = QuoteNotifier(dataSource);

      notifier.addQuote(sampleQuote1);
      notifier.addQuote(sampleQuote2);
    });

    test('toggleFavorite toggles favorite flag and persists', () {
      expect(
        notifier.state.firstWhere((q) => q.id == 'q-1').isFavorite,
        isFalse,
      );

      notifier.toggleFavorite('q-1');
      expect(
        notifier.state.firstWhere((q) => q.id == 'q-1').isFavorite,
        isTrue,
      );

      notifier.toggleFavorite('q-1');
      expect(
        notifier.state.firstWhere((q) => q.id == 'q-1').isFavorite,
        isFalse,
      );
    });

    test('updateQuote replaces existing quote in state', () {
      final updatedQuote = sampleQuote1.copyWith(
        text: 'Hayat gerçekten cesurları sever!',
        author: 'Motive Edici',
      );

      notifier.updateQuote(updatedQuote);

      final found = notifier.state.firstWhere((q) => q.id == 'q-1');
      expect(found.text, 'Hayat gerçekten cesurları sever!');
      expect(found.author, 'Motive Edici');
    });

    test('renameCategory updates category for all matching quotes', () {
      notifier.renameCategory('Felsefe', 'Derin Düşünceler');

      final quote = notifier.state.firstWhere((q) => q.id == 'q-2');
      expect(quote.categoryName, 'Derin Düşünceler');

      final unchanged = notifier.state.firstWhere((q) => q.id == 'q-1');
      expect(unchanged.categoryName, 'Motivasyon');
    });

    test('handleCategoryDeleted moves quotes from deleted category to Genel', () {
      notifier.handleCategoryDeleted('Felsefe');

      final quote = notifier.state.firstWhere((q) => q.id == 'q-2');
      expect(quote.categoryName, 'Genel');
    });
  });

  group('Quote Providers Filtering & Search Tests', () {
    late SharedPreferences prefs;

    final quotes = [
      Quote(
        id: '1',
        text: 'Kendine inan.',
        author: 'Ali Veli',
        categoryName: 'Motivasyon',
        createdAt: DateTime.now(),
        isFavorite: true,
      ),
      Quote(
        id: '2',
        text: 'Sorgulanmamış bir hayat yaşanmaya değmez.',
        author: 'Sokrates',
        categoryName: 'Felsefe',
        createdAt: DateTime.now(),
        isFavorite: false,
      ),
      Quote(
        id: '3',
        text: 'Gözlerini kapat ve derin nefes al.',
        author: 'Zehra',
        categoryName: 'Huzur',
        createdAt: DateTime.now(),
        isFavorite: true,
      ),
    ];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('favoriteQuoteListProvider returns only favorite quotes', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final quoteNotifier = container.read(quoteListProvider.notifier);
      for (final q in quotes) {
        quoteNotifier.addQuote(q);
      }

      final favorites = container.read(favoriteQuoteListProvider);
      expect(favorites.length, 2);
      expect(favorites.every((q) => q.isFavorite), isTrue);
    });

    test('filteredQuoteListProvider filters by category and search query', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final quoteNotifier = container.read(quoteListProvider.notifier);
      for (final q in quotes) {
        quoteNotifier.addQuote(q);
      }

      // 1. Hepsi & empty query -> all 3
      expect(container.read(filteredQuoteListProvider).length, 3);

      // 2. Filter by Category 'Felsefe'
      container.read(selectedCategoryFilterProvider.notifier).state = 'Felsefe';
      expect(container.read(filteredQuoteListProvider).length, 1);
      expect(container.read(filteredQuoteListProvider).first.author, 'Sokrates');

      // 3. Search query filter
      container.read(selectedCategoryFilterProvider.notifier).state = 'Hepsi';
      container.read(searchQueryProvider.notifier).state = 'Sokrates';
      expect(container.read(filteredQuoteListProvider).length, 1);
      expect(container.read(filteredQuoteListProvider).first.id, '2');

      // 4. Search query in quote text
      container.read(searchQueryProvider.notifier).state = 'nefes';
      expect(container.read(filteredQuoteListProvider).length, 1);
      expect(container.read(filteredQuoteListProvider).first.id, '3');
    });
  });

  group('QuoteOfDayNotifier Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Returns default fallback quote when pool is empty', () {
      final notifier = QuoteOfDayNotifier(prefs);
      final quote = notifier.getOrUpdateQuoteOfDay([]);

      expect(quote.id, HomeWidgetService.defaultFallbackQuote.id);
      expect(quote.text, HomeWidgetService.defaultFallbackQuote.text);
    });

    test('Picks a quote and caches it in SharedPreferences', () {
      final sample = Quote(
        id: 'daily-1',
        text: 'Her gün yeni bir başlangıçtır.',
        author: 'Anonim',
        categoryName: 'Motivasyon',
        createdAt: DateTime.now(),
      );

      final notifier = QuoteOfDayNotifier(prefs);
      final quote = notifier.getOrUpdateQuoteOfDay([sample]);

      expect(quote.id, 'daily-1');
      expect(prefs.getString('quoteOfDay_id'), 'daily-1');
      expect(prefs.getString('quoteOfDay_time'), isNotNull);

      // Calling again should return cached quote
      final cachedQuote = notifier.getOrUpdateQuoteOfDay([sample]);
      expect(cachedQuote.id, 'daily-1');
    });
  });
}
