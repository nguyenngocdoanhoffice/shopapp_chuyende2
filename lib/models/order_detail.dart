import 'app_user.dart';

class OrderDetailItem {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const OrderDetailItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory OrderDetailItem.fromMap(Map<String, dynamic> map) {
    final productMap = map['products'] as Map<String, dynamic>?;
    return OrderDetailItem(
      productName: productMap?['name'] as String? ?? 'Sản phẩm',
      quantity: map['quantity'] as int? ?? 0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
      lineTotal: (map['line_total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OrderDetail {
  final int id;
  final String status;
  final String paymentMethod;
  final String shippingAddress;
  final double totalAmount;
  final DateTime? createdAt;
  final AppUser? user;
  final List<OrderDetailItem> items;

  const OrderDetail({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.totalAmount,
    required this.createdAt,
    required this.user,
    required this.items,
  });

  factory OrderDetail.fromMap(Map<String, dynamic> map) {
    final userMap = map['users'] as Map<String, dynamic>?;
    final rawItems = map['order_items'] as List<dynamic>? ?? [];

    return OrderDetail(
      id: map['id'] as int,
      status: map['status'] as String? ?? 'pending',
      paymentMethod: map['payment_method'] as String? ?? 'cod',
      shippingAddress: map['shipping_address'] as String? ?? '',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
      user: userMap == null ? null : AppUser.fromMap(userMap),
      items: rawItems
          .map((item) => OrderDetailItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
