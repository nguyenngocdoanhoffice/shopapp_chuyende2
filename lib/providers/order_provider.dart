import 'package:flutter/foundation.dart';

import '../models/coupon.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../services/coupon_service.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService;
  final CouponService _couponService;

  OrderProvider(this._orderService, this._couponService);

  List<Order> orders = [];
  Coupon? appliedCoupon;
  bool isLoading = false;
  String? error;

  Future<void> loadMyOrders() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      orders = await _orderService.getMyOrders();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<double> applyCoupon({
    required String code,
    required double subtotal,
  }) async {
    final coupon = await _couponService.validateCoupon(code);
    if (coupon == null) {
      throw Exception('Coupon is invalid or expired');
    }

    final discount = _orderService.calculateDiscount(
      coupon: coupon,
      subtotal: subtotal,
    );

    if (discount <= 0) {
      throw Exception('Subtotal does not meet coupon minimum amount');
    }

    appliedCoupon = coupon;
    notifyListeners();
    return discount;
  }

  void removeCoupon() {
    appliedCoupon = null;
    notifyListeners();
  }

  Future<void> checkout({
    required CartProvider cartProvider,
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    await _orderService.checkout(
      cartItems: cartProvider.items,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      coupon: appliedCoupon,
    );
    await cartProvider.clearCart();
    appliedCoupon = null;
    await loadMyOrders();
  }
}
