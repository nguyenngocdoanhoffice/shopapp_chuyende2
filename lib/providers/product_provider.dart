import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService;

  ProductProvider(this._productService);

  List<Product> products = [];
  List<String> categories = ['All'];
  String selectedCategory = 'All';
  String searchKeyword = '';
  bool isLoading = false;
  String? error;

  Future<void> loadInitialData() async {
    await Future.wait([loadCategories(), loadProducts()]);
  }

  Future<void> loadCategories() async {
    try {
      categories = await _productService.getCategories();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      products = await _productService.getProducts(
        search: searchKeyword,
        category: selectedCategory,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSearch(String value) async {
    searchKeyword = value;
    await loadProducts();
  }

  Future<void> setCategory(String value) async {
    selectedCategory = value;
    await loadProducts();
  }

  Future<void> createProduct({
    required String name,
    required String description,
    required String category,
    required double price,
    required int stock,
    String? imageUrl,
  }) async {
    await _productService.createProduct(
      name: name,
      description: description,
      category: category,
      price: price,
      stock: stock,
      imageUrl: imageUrl,
    );
    await loadInitialData();
  }

  Future<void> updateProduct({
    required int id,
    required String name,
    required String description,
    required String category,
    required double price,
    required int stock,
    String? imageUrl,
    required bool isActive,
  }) async {
    await _productService.updateProduct(
      id: id,
      name: name,
      description: description,
      category: category,
      price: price,
      stock: stock,
      imageUrl: imageUrl,
      isActive: isActive,
    );
    await loadInitialData();
  }

  Future<void> deleteProduct(int id) async {
    await _productService.deleteProduct(id);
    await loadProducts();
  }
}
