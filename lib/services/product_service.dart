import '../models/product.dart';
import '../supabase_client.dart';

class ProductService {
  Future<List<Product>> getProducts({String? search, String? category}) async {
    dynamic query = supabase.from('products').select().eq('is_active', true);

    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('name', '%${search.trim()}%');
    }
    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.eq('category', category);
    }

    final data = await query.order('created_at', ascending: false);
    return data.map((item) => Product.fromMap(item)).toList();
  }

  Future<List<String>> getCategories() async {
    final data = await supabase.from('products').select('category');
    final categories = data
        .map((item) => item['category'] as String? ?? 'Other')
        .toSet()
        .toList();
    categories.sort();
    return ['All', ...categories];
  }

  Future<Product> getProductById(int id) async {
    final data = await supabase.from('products').select().eq('id', id).single();
    return Product.fromMap(data);
  }

  Future<void> createProduct({
    required String name,
    required String description,
    required String category,
    required double price,
    required int stock,
    String? imageUrl,
    bool isActive = true,
  }) async {
    await supabase.from('products').insert({
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
      'is_active': isActive,
    });
  }

  Future<void> updateProduct({
    required int id,
    required String name,
    required String description,
    required String category,
    required double price,
    required int stock,
    String? imageUrl,
    bool isActive = true,
  }) async {
    await supabase.from('products').update({
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
      'is_active': isActive,
    }).eq('id', id);
  }

  Future<void> deleteProduct(int id) async {
    await supabase.from('products').delete().eq('id', id);
  }
}
