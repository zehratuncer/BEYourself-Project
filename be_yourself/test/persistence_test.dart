import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:be_yourself/features/quote/domain/entities/quote.dart';
import 'package:be_yourself/features/quote/data/datasources/quote_local_datasource.dart';
import 'package:be_yourself/features/quote/presentation/providers/quote_providers.dart';
import 'package:be_yourself/features/category/domain/entities/category.dart';
import 'package:be_yourself/features/category/data/datasources/category_local_datasource.dart';
import 'package:be_yourself/features/category/presentation/providers/category_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Data Persistence Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Quote JSON serialization and LocalDataSource persistence', () async {
      final dataSource = QuoteLocalDataSource(prefs);

      // Initially empty
      expect(dataSource.getQuotes(), isEmpty);

      final quote = Quote(
        id: 'test-1',
        text: 'Kendini bil.',
        author: 'Sokrates',
        categoryName: 'Felsefe',
        createdAt: DateTime(2026, 1, 1),
        isFavorite: true,
      );

      await dataSource.saveQuotes([quote]);

      final loadedQuotes = dataSource.getQuotes();
      expect(loadedQuotes.length, 1);
      expect(loadedQuotes.first.id, 'test-1');
      expect(loadedQuotes.first.text, 'Kendini bil.');
      expect(loadedQuotes.first.author, 'Sokrates');
      expect(loadedQuotes.first.categoryName, 'Felsefe');
      expect(loadedQuotes.first.isFavorite, true);

      // Multi-media quote test
      final multiMediaQuote = Quote(
        id: 'test-2',
        text: 'Çoklu fotoğraf alıntısı',
        author: 'Fotoğrafçı',
        categoryName: 'Sanat',
        createdAt: DateTime(2026, 1, 2),
        mediaUrls: ['/path/to/img1.jpg', '/path/to/img2.jpg', '/path/to/img3.jpg'],
      );

      expect(multiMediaQuote.allMediaUrls.length, 3);
      final json = multiMediaQuote.toJson();
      final fromJson = Quote.fromJson(json);
      expect(fromJson.allMediaUrls.length, 3);
      expect(fromJson.mediaUrls, contains('/path/to/img2.jpg'));
    });

    test('Category JSON serialization and LocalDataSource default categories', () async {
      final dataSource = CategoryLocalDataSource(prefs);

      // First boot should populate default categories
      final initialCategories = dataSource.getCategories();
      expect(initialCategories.length, CategoryLocalDataSource.defaultCategories.length);
      expect(initialCategories.any((c) => c.name == 'Psikoloji'), true);

      final customCategory = Category(id: 'custom-1', name: 'Bilim');
      await dataSource.saveCategories([...initialCategories, customCategory]);

      final updatedCategories = dataSource.getCategories();
      expect(updatedCategories.length, initialCategories.length + 1);
      expect(updatedCategories.any((c) => c.name == 'Bilim'), true);
    });

    test('QuoteNotifier automatically saves and loads state and clearAllQuotes works', () async {
      final dataSource = QuoteLocalDataSource(prefs);
      final notifier = QuoteNotifier(dataSource);

      expect(notifier.state, isEmpty);

      final newQuote = Quote(
        id: 'q-100',
        text: 'Hayat güzeldir.',
        author: 'Anonim',
        categoryName: 'Motivasyon',
        createdAt: DateTime.now(),
      );

      notifier.addQuote(newQuote);
      expect(notifier.state.length, 1);

      // Create a fresh notifier instance to simulate app restart
      final freshNotifier = QuoteNotifier(dataSource);
      expect(freshNotifier.state.length, 1);
      expect(freshNotifier.state.first.text, 'Hayat güzeldir.');

      // Toggle favorite
      freshNotifier.toggleFavorite('q-100');
      expect(freshNotifier.state.first.isFavorite, true);

      // Clear all quotes
      freshNotifier.clearAllQuotes();
      expect(freshNotifier.state, isEmpty);
      expect(QuoteLocalDataSource(prefs).getQuotes(), isEmpty);
    });

    test('QuoteNotifier syncs widget data and keys when quotes are deleted', () async {
      final dataSource = QuoteLocalDataSource(prefs);
      final notifier = QuoteNotifier(dataSource);

      final q1 = Quote(
        id: 'q-sync-1',
        text: 'Söz 1',
        author: 'Yazar 1',
        categoryName: 'Genel',
        createdAt: DateTime.now(),
      );
      final q2 = Quote(
        id: 'q-sync-2',
        text: 'Söz 2',
        author: 'Yazar 2',
        categoryName: 'Genel',
        createdAt: DateTime.now(),
      );

      notifier.addQuote(q1);
      notifier.addQuote(q2);

      // Simulate q1 was saved as quoteOfDay in prefs
      await prefs.setString('quoteOfDay_id', 'q-sync-1');
      await prefs.setString('quoteOfDay_time', DateTime.now().toIso8601String());

      // Deleting q1 should clear old key and pick new quote q2
      notifier.deleteQuote('q-sync-1');
      expect(prefs.getString('quoteOfDay_id'), 'q-sync-2');

      // Deleting q2 as well leaves state empty
      notifier.deleteQuote('q-sync-2');
      expect(prefs.getString('quoteOfDay_id'), isNull);
    });

    test('CategoryNotifier automatically saves and loads state', () async {
      final dataSource = CategoryLocalDataSource(prefs);
      final notifier = CategoryNotifier(dataSource);

      final initialCount = notifier.state.length;
      notifier.addCategory('Sanat');
      expect(notifier.state.length, initialCount + 1);

      // Simulate app restart
      final freshNotifier = CategoryNotifier(dataSource);
      expect(freshNotifier.state.any((c) => c.name == 'Sanat'), true);

      final sanatCat = freshNotifier.state.firstWhere((c) => c.name == 'Sanat');
      freshNotifier.updateCategory(sanatCat.id, 'Güzel Sanatlar');
      expect(freshNotifier.state.any((c) => c.name == 'Güzel Sanatlar'), true);

      // Re-read from disk
      final reloaded = CategoryLocalDataSource(prefs).getCategories();
      expect(reloaded.any((c) => c.name == 'Güzel Sanatlar'), true);
    });
  });
}
