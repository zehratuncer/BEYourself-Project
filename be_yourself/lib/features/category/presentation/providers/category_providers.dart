import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quote_reminder/features/category/domain/entities/category.dart';

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
    if (name.trim().isEmpty) return;
    final newCategory = Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      quoteCount: 0,
    );
    state = [...state, newCategory];
  }
}

final categoryListProvider =
    StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier();
});
