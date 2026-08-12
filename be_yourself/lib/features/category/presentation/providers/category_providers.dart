import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:be_yourself/features/category/data/datasources/category_local_datasource.dart';
import 'package:be_yourself/features/category/domain/entities/category.dart';
import 'package:be_yourself/main.dart';

class CategoryNotifier extends StateNotifier<List<Category>> {
  final CategoryLocalDataSource _dataSource;

  CategoryNotifier(this._dataSource) : super([]) {
    _loadCategories();
  }

  void _loadCategories() {
    state = _dataSource.getCategories();
  }

  void _persist() {
    _dataSource.saveCategories(state);
  }

  void addCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (state.any((c) => c.name.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    final newCategory = Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: trimmed,
      quoteCount: 0,
    );
    state = [...state, newCategory];
    _persist();
  }

  void updateCategory(String id, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    state = [
      for (final category in state)
        if (category.id == id) category.copyWith(name: trimmed) else category,
    ];
    _persist();
  }

  void deleteCategory(String id) {
    state = state.where((category) => category.id != id).toList();
    _persist();
  }
}

final categoryLocalDataSourceProvider =
    Provider<CategoryLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CategoryLocalDataSource(prefs);
});

final categoryListProvider =
    StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  final dataSource = ref.watch(categoryLocalDataSourceProvider);
  return CategoryNotifier(dataSource);
});


