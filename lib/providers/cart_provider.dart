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

  Future<void> addItem(int productId, {int quantity = 1}) async {
    await _cartService.addToCart(productId: productId, quantity: quantity);
    await loadCart();
  }

  Future<void> updateItemQty(int cartItemId, int quantity) async {
    await _cartService.updateQuantity(cartItemId: cartItemId, quantity: quantity);
    await loadCart();
  }

  Future<void> removeItem(int cartItemId) async {
    await _cartService.removeItem(cartItemId);
    await loadCart();
  }

  Future<void> clearCart() async {
    await _cartService.clearCart();
    await loadCart();
  }
}
