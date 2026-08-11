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

    test('QuoteNotifier automatically saves and loads state', () async {
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

      // Re-read directly from disk
      final reloadedFromDisk = QuoteLocalDataSource(prefs).getQuotes();
      expect(reloadedFromDisk.first.isFavorite, true);

      // Delete quote
      freshNotifier.deleteQuote('q-100');
      expect(freshNotifier.state, isEmpty);
      expect(QuoteLocalDataSource(prefs).getQuotes(), isEmpty);
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
