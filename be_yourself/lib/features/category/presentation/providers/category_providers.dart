import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:be_yourself/features/category/domain/entities/category.dart';

class CategoryNotifier extends StateNotifier<List<Category>> {
  CategoryNotifier()
      : super([
          const Category(id: '1', name: 'Psikoloji', quoteCount: 14),
          const Category(id: '2', name: 'Motivasyon', quoteCount: 28),
          const Category(id: '3', name: 'Kitaplar', quoteCount: 19),
          const Category(id: '4', name: 'Müzik', quoteCount: 8),
          const Category(id: '5', name: 'Felsefe', quoteCount: 22),
        ]);

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
  }

  void updateCategory(String id, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    state = [
      for (final category in state)
        if (category.id == id) category.copyWith(name: trimmed) else category,
    ];
  }

  void deleteCategory(String id) {
    state = state.where((category) => category.id != id).toList();
  }
}

final categoryListProvider =
    StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier();
});

