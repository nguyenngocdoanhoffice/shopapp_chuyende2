import '../models/cart_item.dart';
import '../supabase_client.dart';

class CartService {
  Future<int> _getProductStock(int productId) async {
    final product = await supabase
        .from('products')
        .select('stock')
        .eq('id', productId)
        .single();

    return (product['stock'] as int?) ?? 0;
  }

  Future<int> _ensureCartId() async {
    // Moi user co 1 cart. Neu chua co thi tao moi va tra ve cart id.
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not authenticated');
    }

    final existing = await supabase
        .from('carts')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as int;
    }

    final created = await supabase
        .from('carts')
        .insert({'user_id': userId})
        .select('id')
        .single();

    return created['id'] as int;
  }

  Future<List<CartItem>> getCartItems() async {
    // Nguon du lieu: cart_items join products theo cart_id hien tai.
    final cartId = await _ensureCartId();

    final data = await supabase
        .from('cart_items')
        .select('*, products(*)')
        .eq('cart_id', cartId)
        .order('id');

    return data.map((item) => CartItem.fromMap(item)).toList();
  }

  Future<CartItem> addToCart({
    required int productId,
    required int quantity,
  }) async {
    // Lay gia hien tai tu products, sau do insert hoac cong don so luong neu da ton tai item.
    final cartId = await _ensureCartId();
    final stock = await _getProductStock(productId);
    if (quantity > stock) {
      throw Exception('Số lượng vượt quá tồn kho. Chỉ còn $stock sản phẩm.');
    }

    final product = await supabase
        .from('products')
        .select('price')
        .eq('id', productId)
        .single();

    final unitPrice = (product['price'] as num).toDouble();

    final existing = await supabase
        .from('cart_items')
        .select('id, quantity')
        .eq('cart_id', cartId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing == null) {
      final inserted = await supabase
          .from('cart_items')
          .insert({
            'cart_id': cartId,
            'product_id': productId,
            'quantity': quantity,
            'unit_price': unitPrice,
          })
          .select('*, products(*)')
          .single();

      return CartItem.fromMap(inserted);
    }

    final currentQty = existing['quantity'] as int;
    if (currentQty + quantity > stock) {
      throw Exception(
        'Số lượng vượt quá tồn kho. Chỉ còn ${stock - currentQty} sản phẩm có thể thêm.',
      );
    }

    final updated = await supabase
        .from('cart_items')
        .update({'quantity': currentQty + quantity})
        .eq('id', existing['id'] as int)
        .select('*, products(*)')
        .single();

    return CartItem.fromMap(updated);
  }

  Future<CartItem> updateQuantity({
    required int cartItemId,
    required int quantity,
  }) async {
    // Neu quantity <= 0 thi xoa item khoi gio.
    if (quantity <= 0) {
      await removeItem(cartItemId);
      return Future.error(Exception('Quantity must be greater than zero'));
    }

    final cartItem = await supabase
        .from('cart_items')
        .select('id, product_id, quantity, products(stock)')
        .eq('id', cartItemId)
        .single();

    final productMap = cartItem['products'] as Map<String, dynamic>?;
    final stock = (productMap?['stock'] as int?) ?? 0;
    if (quantity > stock) {
      throw Exception('Số lượng vượt quá tồn kho. Chỉ còn $stock sản phẩm.');
    }

    final updated = await supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', cartItemId)
        .select('*, products(*)')
        .single();

    return CartItem.fromMap(updated);
  }

  Future<void> removeItem(int cartItemId) async {
    await supabase.from('cart_items').delete().eq('id', cartItemId);
  }

  Future<void> clearCart() async {
    // Xoa toan bo item cua gio hien tai (thuong goi sau checkout thanh cong).
    final cartId = await _ensureCartId();
    await supabase.from('cart_items').delete().eq('cart_id', cartId);
  }
}
