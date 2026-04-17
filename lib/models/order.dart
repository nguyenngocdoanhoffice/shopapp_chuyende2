import 'order_item.dart';

class Order {
  final int id;
  final String status;
  final String paymentMethod;
  final double subtotal;
  final double discountAmount;
  final double shippingFee;
  final double totalAmount;
  final String shippingAddress;
  final DateTime createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.subtotal,
    required this.discountAmount,
    required this.shippingFee,
    required this.totalAmount,
    required this.shippingAddress,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    final rawItems = map['order_items'] as List<dynamic>? ?? [];

    return Order(
      id: map['id'] as int,
      status: map['status'] as String? ?? 'pending',
      paymentMethod: map['payment_method'] as String? ?? 'cod',
      subtotal: (map['subtotal'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      shippingFee: (map['shipping_fee'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num).toDouble(),
      shippingAddress: map['shipping_address'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      items: rawItems
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
