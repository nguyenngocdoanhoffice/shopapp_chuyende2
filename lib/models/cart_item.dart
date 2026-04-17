import 'product.dart';

class CartItem {
  final int id;
  final int productId;
  final int quantity;
  final double unitPrice;
  final Product? product;

  const CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.product,
  });

  double get lineTotal => quantity * unitPrice;

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final productMap = map['products'] as Map<String, dynamic>?;

    return CartItem(
      id: map['id'] as int,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      product: productMap != null ? Product.fromMap(productMap) : null,
    );
  }
}
