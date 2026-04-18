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
    // Tai dong thoi danh muc filter va danh sach san pham.
    await Future.wait([loadCategories(), loadProducts()]);
  }

  Future<void> loadCategories() async {
    try {
      // Danh muc nay dung cho bo loc tren Home, du lieu lay tu cot products.category.
      categories = await _productService.getCategories();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    try {
      // Query san pham voi 2 dieu kien dong: tu khoa tim kiem + danh muc dang chon.
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
    // Cap nhat state tim kiem va tai lai danh sach.
    searchKeyword = value;
    await loadProducts();
  }

  Future<void> setCategory(String value) async {
    // Cap nhat category filter va tai lai danh sach.
    selectedCategory = value;
    await loadProducts();
  }

  Future<void> createProduct({
    required String name,
    required String description,
    required String category,
    int? categoryId,
    required double price,
    required int stock,
    String? imageUrl,
  }) async {
    // Tao san pham qua ProductService, sau do refresh ca category + products.
    await _productService.createProduct(
      name: name,
      description: description,
      category: category,
      categoryId: categoryId,
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
    int? categoryId,
    required double price,
    required int stock,
    String? imageUrl,
    required bool isActive,
  }) async {
    // Sua san pham qua ProductService, sau do refresh du lieu hien thi.
    await _productService.updateProduct(
      id: id,
      name: name,
      description: description,
      category: category,
      categoryId: categoryId,
      price: price,
      stock: stock,
      imageUrl: imageUrl,
      isActive: isActive,
    );
    await loadInitialData();
  }

  Future<void> deleteProduct(int id) async {
    // Xoa san pham va tai lai danh sach hien tai.
    await _productService.deleteProduct(id);
    await loadProducts();
  }
}
