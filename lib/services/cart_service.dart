import '../models/cart_item.dart';
import '../supabase_client.dart';

class CartService {
  Future<int> _ensureCartId() async {
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
    final cartId = await _ensureCartId();

    final data = await supabase
        .from('cart_items')
        .select('*, products(*)')
        .eq('cart_id', cartId)
        .order('id');

    return data.map((item) => CartItem.fromMap(item)).toList();
  }

  Future<void> addToCart({
    required int productId,
    required int quantity,
  }) async {
    final cartId = await _ensureCartId();
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
      await supabase.from('cart_items').insert({
        'cart_id': cartId,
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
      });
      return;
    }

    final currentQty = existing['quantity'] as int;
    await supabase
        .from('cart_items')
        .update({'quantity': currentQty + quantity})
        .eq('id', existing['id'] as int);
  }

  Future<void> updateQuantity({
    required int cartItemId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeItem(cartItemId);
      return;
    }

    await supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', cartItemId);
  }

  Future<void> removeItem(int cartItemId) async {
    await supabase.from('cart_items').delete().eq('id', cartItemId);
  }

  Future<void> clearCart() async {
    final cartId = await _ensureCartId();
    await supabase.from('cart_items').delete().eq('cart_id', cartId);
  }
}
