import 'product.dart';

class OrderItem {
  final int id;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final Product? product;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.product,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    final productMap = map['products'] as Map<String, dynamic>?;

    return OrderItem(
      id: map['id'] as int,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      lineTotal: (map['line_total'] as num).toDouble(),
      product: productMap != null ? Product.fromMap(productMap) : null,
    );
  }
}
