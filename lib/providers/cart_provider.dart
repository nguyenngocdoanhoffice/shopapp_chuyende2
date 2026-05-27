import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService;

  CartProvider(this._cartService);

  List<CartItem> items = [];
  bool isLoading = false;
  String? error;

  double get subtotal =>
      items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  int get totalItems => items.fold<int>(0, (sum, item) => sum + item.quantity);

  Future<void> loadCart() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      items = await _cartService.getCartItems();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addItem(int productId, {int quantity = 1}) async {
    try {
      final addedItem = await _cartService.addToCart(
        productId: productId,
        quantity: quantity,
      );

      final existingIndex = items.indexWhere(
        (item) => item.productId == addedItem.productId,
      );

      if (existingIndex == -1) {
        items = [...items, addedItem];
      } else {
        items[existingIndex] = addedItem;
      }

      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItemQty(int cartItemId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeItem(cartItemId);
        return true;
      }

      final updatedItem = await _cartService.updateQuantity(
        cartItemId: cartItemId,
        quantity: quantity,
      );

      final index = items.indexWhere((item) => item.id == cartItemId);
      if (index != -1) {
        items[index] = updatedItem;
        error = null;
        notifyListeners();
      }
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeItem(int cartItemId) async {
    try {
      await _cartService.removeItem(cartItemId);
      items.removeWhere((item) => item.id == cartItemId);
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> clearCart() async {
    try {
      await _cartService.clearCart();
      items = [];
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
