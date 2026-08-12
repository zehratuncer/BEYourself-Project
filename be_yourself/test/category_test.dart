import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:be_yourself/core/utils/category_icon_helper.dart';
import 'package:be_yourself/features/category/data/datasources/category_local_datasource.dart';
import 'package:be_yourself/features/category/presentation/providers/category_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CategoryIconHelper Tests', () {
    test('Returns correct icons based on category name keywords', () {
      expect(
        CategoryIconHelper.getIconForCategory('Psikoloji'),
        Icons.psychology_rounded,
      );
      expect(
        CategoryIconHelper.getIconForCategory('Zihin ve Ruh'),
        Icons.psychology_rounded,
      );
      expect(
        CategoryIconHelper.getIconForCategory('Motivasyon'),
        Icons.fitness_center_rounded,
      );
      expect(
        CategoryIconHelper.getIconForCategory('Başarı ve Hedef'),
        Icons.fitness_center_rounded,
      );
      expect(
        CategoryIconHelper.getIconForCategory('Kitap ve Edebiyat'),
        Icons.menu_book_rounded,
      );
      expect(
        CategoryIconHelper.getIconForCategory('Müzik ve Sanat'),
        Icons.music_note_rounded,
      );
      expect(
        CategoryIconHelper.getIconForCategory('Felsefe ve Bilgelik'),
        Icons.school_rounded,
      );
      expect(
        CategoryIconHelper.getIconForCategory('Aşk ve Sevgi'),
        Icons.favorite_rounded,
      );
      expect(
        CategoryIconHelper.getIconForCategory('Doğa ve Huzur'),
        Icons.spa_rounded,
      );
      expect(
        CategoryIconHelper.getIconForCategory('İş ve Kariyer'),
        Icons.work_outline_rounded,
      );
      expect(
        CategoryIconHelper.getIconForCategory('Seyahat ve Gezi'),
        Icons.explore_rounded,
      );
      expect(
        CategoryIconHelper.getIconForCategory('Bilim ve Teknoloji'),
        Icons.lightbulb_rounded,
      );
    });

    test('Returns fallback grid icon for unknown category names', () {
      expect(
        CategoryIconHelper.getIconForCategory('Bilinmeyen Kategori'),
        Icons.grid_view_rounded,
      );
      expect(
        CategoryIconHelper.getIconForCategory(''),
        Icons.grid_view_rounded,
      );
    });
  });

  group('CategoryNotifier Business Logic Tests', () {
    late SharedPreferences prefs;
    late CategoryLocalDataSource dataSource;
    late CategoryNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      dataSource = CategoryLocalDataSource(prefs);
      notifier = CategoryNotifier(dataSource);
    });

    test('Initial state loads default categories', () {
      expect(notifier.state, isNotEmpty);
      expect(notifier.state.any((c) => c.name == 'Motivasyon'), isTrue);
      expect(notifier.state.any((c) => c.name == 'Felsefe'), isTrue);
    });

    test('addCategory adds a new unique category', () {
      final initialCount = notifier.state.length;

      notifier.addCategory('  Astronomi  ');

      expect(notifier.state.length, initialCount + 1);
      expect(notifier.state.any((c) => c.name == 'Astronomi'), isTrue);
    });

    test('addCategory ignores empty names or duplicates case-insensitively', () {
      final count = notifier.state.length;

      notifier.addCategory('   ');
      expect(notifier.state.length, count);

      notifier.addCategory('motivasyon'); // Already exists as 'Motivasyon'
      expect(notifier.state.length, count);
    });

    test('updateCategory modifies category name and persists', () {
      final category = notifier.state.first;

      notifier.updateCategory(category.id, 'Yeni İsim');

      expect(
        notifier.state.firstWhere((c) => c.id == category.id).name,
        'Yeni İsim',
      );

      // Verify persistence by reloading
      final reloadedNotifier = CategoryNotifier(dataSource);
      expect(
        reloadedNotifier.state.firstWhere((c) => c.id == category.id).name,
        'Yeni İsim',
      );
    });

    test('updateCategory ignores empty new name', () {
      final category = notifier.state.first;
      final originalName = category.name;

      notifier.updateCategory(category.id, '   ');

      expect(
        notifier.state.firstWhere((c) => c.id == category.id).name,
        originalName,
      );
    });

    test('deleteCategory removes category and persists', () {
      final categoryToDelete = notifier.state.first;
      final initialCount = notifier.state.length;

      notifier.deleteCategory(categoryToDelete.id);

      expect(notifier.state.length, initialCount - 1);
      expect(
        notifier.state.any((c) => c.id == categoryToDelete.id),
        isFalse,
      );

      // Verify persistence
      final reloadedNotifier = CategoryNotifier(dataSource);
      expect(
        reloadedNotifier.state.any((c) => c.id == categoryToDelete.id),
        isFalse,
      );
    });
  });
}
