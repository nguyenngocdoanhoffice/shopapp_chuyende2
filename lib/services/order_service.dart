import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/coupon.dart';
import '../models/order_detail.dart';
import '../supabase_client.dart';

class OrderService {
  double calculateDiscount({required Coupon coupon, required double subtotal}) {
    // Tinh giam gia theo 2 kieu:
    // - percent: theo phan tram, co the bi gioi han boi maxDiscount
    // - fixed: giam truc tiep, khong vuot qua subtotal
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

    final cartItemsPayload = cartItems
        .map(
          (item) => {'product_id': item.productId, 'quantity': item.quantity},
        )
        .toList();

    await supabase.rpc(
      'create_order_with_stock_check',
      params: {
        'p_shipping_address': shippingAddress,
        'p_payment_method': paymentMethod,
        'p_cart_items': cartItemsPayload,
        'p_coupon_id': coupon?.id,
      },
    );
  }

  Future<List<Order>> getMyOrders() async {
    // Lay lich su don cua user hien tai (orders + order_items + products).
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }

    final data =
        await supabase
                .from('orders')
                .select('*, order_items(*, products(*))')
                .eq('user_id', userId)
                .order('created_at', ascending: false)
            as List<dynamic>;

    return data
        .map((item) => Order.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Order>> getAllOrders() async {
    // Du lieu cho admin dashboard: toan bo orders, moi nhat truoc.
    final data =
        await supabase
                .from('orders')
                .select('*, order_items(*, products(*))')
                .order('created_at', ascending: false)
            as List<dynamic>;
    return data
        .map((item) => Order.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    // Cap nhat trang thai don hang theo id.
    await supabase.from('orders').update({'status': status}).eq('id', orderId);
  }

  Future<OrderDetail> getOrderDetailById(int orderId) async {
    // Chi tiet don cho admin: join users + order_items + products(name).
    final data = await supabase
        .from('orders')
        .select('''
          *,
          users(id, email, full_name, phone, address, role, created_at),
          order_items(quantity, unit_price, line_total, products(name))
        ''')
        .eq('id', orderId)
        .single();

    return OrderDetail.fromMap(data);
  }
}
