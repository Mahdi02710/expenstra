import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryItem {
  final String name;
  final String icon;

  const CategoryItem({required this.name, required this.icon});

  Map<String, dynamic> toJson() => {'name': name, 'icon': icon};

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      name: json['name'] as String,
      icon: json['icon'] as String,
    );
  }
}

class CategoryService {
  static const _customCategoriesKey = 'custom_categories_v1';
  static final CategoryService _instance = CategoryService._internal();

  factory CategoryService() => _instance;

  CategoryService._internal();

  List<CategoryItem> get defaultCategories => const [
        CategoryItem(name: 'Food & Drink', icon: '🍔'),
        CategoryItem(name: 'Transportation', icon: '🚗'),
        CategoryItem(name: 'Shopping', icon: '🛍️'),
        CategoryItem(name: 'Housing', icon: '🏠'),
        CategoryItem(name: 'Entertainment', icon: '🎬'),
        CategoryItem(name: 'Health & Fitness', icon: '💊'),
        CategoryItem(name: 'Education', icon: '📚'),
        CategoryItem(name: 'Bills & Utilities', icon: '💡'),
        CategoryItem(name: 'Income', icon: '💵'),
        CategoryItem(name: 'Other', icon: '💰'),
      ];

  Future<List<CategoryItem>> getCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_customCategoriesKey) ?? [];
    return raw
        .map((entry) {
          try {
            return CategoryItem.fromJson(jsonDecode(entry));
          } catch (_) {
            return null;
          }
        })
        .whereType<CategoryItem>()
        .toList();
  }

  Future<void> addCustomCategory(CategoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_customCategoriesKey) ?? [];
    raw.add(jsonEncode(item.toJson()));
    await prefs.setStringList(_customCategoriesKey, raw);
  }

  Future<void> removeCustomCategory(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_customCategoriesKey) ?? [];
    final updated = raw.where((entry) {
      try {
        final item = CategoryItem.fromJson(jsonDecode(entry));
        return item.name != name;
      } catch (_) {
        return false;
      }
    }).toList();
    await prefs.setStringList(_customCategoriesKey, updated);
  }
}
