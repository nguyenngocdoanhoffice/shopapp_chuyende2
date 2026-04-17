import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/coupon.dart';
import '../supabase_client.dart';

class OrderService {
  double calculateDiscount({required Coupon coupon, required double subtotal}) {
    if (subtotal < coupon.minOrderAmount) {
      return 0;
    }

    if (coupon.discountType == 'percent') {
      final raw = subtotal * coupon.discountValue / 100;
      if (coupon.maxDiscount == null) {
        return raw;
      }
      return raw > coupon.maxDiscount! ? coupon.maxDiscount! : raw;
    }

    final fixed = coupon.discountValue;
    return fixed > subtotal ? subtotal : fixed;
  }

  Future<void> checkout({
    required List<CartItem> cartItems,
    required String shippingAddress,
    required String paymentMethod,
    Coupon? coupon,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not authenticated');
    }
    if (cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    final subtotal = cartItems.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
    final discount = coupon == null
        ? 0.0
        : calculateDiscount(coupon: coupon, subtotal: subtotal);
    const shippingFee = 5.0;
    final total = subtotal - discount + shippingFee;

    final order = await supabase
        .from('orders')
        .insert({
          'user_id': userId,
          'coupon_id': coupon?.id,
          'status': 'pending',
          'payment_method': paymentMethod,
          'subtotal': subtotal,
          'discount_amount': discount,
          'shipping_fee': shippingFee,
          'total_amount': total,
          'shipping_address': shippingAddress,
        })
        .select('id')
        .single();

    final orderId = order['id'] as int;

    final itemsPayload = cartItems
        .map(
          (item) => {
            'order_id': orderId,
            'product_id': item.productId,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'line_total': item.lineTotal,
          },
        )
        .toList();

    await supabase.from('order_items').insert(itemsPayload);

    if (coupon != null) {
      await supabase.rpc(
        'increment_coupon_usage',
        params: {'coupon_id': coupon.id},
      );
    }
  }

  Future<List<Order>> getMyOrders() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }

    final data = await supabase
        .from('orders')
        .select('*, order_items(*, products(*))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return data.map((item) => Order.fromMap(item)).toList();
  }

  Future<List<Order>> getAllOrders() async {
    final data = await supabase
        .from('orders')
        .select('*, order_items(*, products(*))')
        .order('created_at', ascending: false);
    return data.map((item) => Order.fromMap(item)).toList();
  }

  Future<void> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    await supabase.from('orders').update({'status': status}).eq('id', orderId);
  }
}
