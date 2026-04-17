import 'package:flutter/foundation.dart';

import '../models/coupon.dart';
import '../models/order.dart';
import '../services/coupon_service.dart';
import '../services/order_service.dart';

class AdminProvider extends ChangeNotifier {
  final OrderService _orderService;
  final CouponService _couponService;

  AdminProvider(this._orderService, this._couponService);

  List<Order> allOrders = [];
  List<Coupon> coupons = [];
  bool isLoading = false;
  String? error;

  Future<void> loadDashboardData() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      allOrders = await _orderService.getAllOrders();
      coupons = await _couponService.getCoupons();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    await _orderService.updateOrderStatus(orderId: orderId, status: status);
    await loadDashboardData();
  }

  Future<void> createCoupon({
    required String code,
    required String discountType,
    required double discountValue,
    required double minOrderAmount,
    double? maxDiscount,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    await _couponService.createCoupon(
      code: code,
      discountType: discountType,
      discountValue: discountValue,
      minOrderAmount: minOrderAmount,
      maxDiscount: maxDiscount,
      startAt: startAt,
      endAt: endAt,
    );
    await loadDashboardData();
  }

  Future<void> toggleCouponStatus(int id, bool isActive) async {
    await _couponService.updateCouponStatus(id: id, isActive: isActive);
    await loadDashboardData();
  }

  Future<void> deleteCoupon(int id) async {
    await _couponService.deleteCoupon(id);
    await loadDashboardData();
  }
}
