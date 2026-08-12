import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:be_yourself/features/category/domain/entities/category.dart';

class CategoryLocalDataSource {
  final SharedPreferences prefs;

  CategoryLocalDataSource(this.prefs);

  static const String _categoriesKey = 'saved_categories_list_v1';

  static const List<Category> defaultCategories = [
    Category(id: '1', name: 'Psikoloji'),
    Category(id: '2', name: 'Motivasyon'),
    Category(id: '3', name: 'Kitaplar'),
    Category(id: '4', name: 'Müzik'),
    Category(id: '5', name: 'Felsefe'),
  ];

  List<Category> getCategories() {
    final rawJson = prefs.getString(_categoriesKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      // First boot: initialize with default categories
      saveCategories(defaultCategories);
      return defaultCategories;
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
      final list = decoded
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList();
      if (list.isEmpty) {
        return defaultCategories;
      }
      return list;
    } catch (e) {
      return defaultCategories;
    }
  }

  Future<bool> saveCategories(List<Category> categories) async {
    final encoded = jsonEncode(categories.map((c) => c.toJson()).toList());
    return await prefs.setString(_categoriesKey, encoded);
  }
}
