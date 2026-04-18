import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService;

  CategoryProvider(this._categoryService);

  List<Category> categories = [];
  bool isLoading = false;
  String? error;

  Future<void> loadCategories() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      categories = await _categoryService.getCategories();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCategory({
    required String name,
    required String description,
  }) async {
    await _categoryService.createCategory(name: name, description: description);
    await loadCategories();
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    required String description,
  }) async {
    await _categoryService.updateCategory(
      id: id,
      name: name,
      description: description,
    );
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _categoryService.deleteCategory(id);
    await loadCategories();
  }
}
