import '../models/product.dart';
import '../supabase_client.dart';

class ProductService {
  Future<List<Product>> getProducts({String? search, String? category}) async {
    // Nguon du lieu: bang products (join them relation categories de doc category_id).
    dynamic query = supabase
        .from('products')
        .select('*, categories(id, name)')
        .eq('is_active', true);

    // Loc theo ten san pham neu co tu khoa.
    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('name', '%${search.trim()}%');
    }
    // Loc theo category text cho man Home (gia tri khac All).
    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.eq('category', category);
    }

    final data =
        await query.order('created_at', ascending: false) as List<dynamic>;
    return data
        .map((item) => Product.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> getCategories() async {
    // Lay category text tu products de tao danh sach bo loc nhanh cho UI.
    final data =
        await supabase.from('products').select('category') as List<dynamic>;
    final categories = data
        .map(
          (item) =>
              (item as Map<String, dynamic>)['category'] as String? ?? 'Other',
        )
        .toSet()
        .toList();
    categories.sort();
    return ['All', ...categories];
  }

  Future<Product> getProductById(int id) async {
    // Lay chi tiet 1 san pham theo id.
    final data = await supabase.from('products').select().eq('id', id).single();
    return Product.fromMap(data);
  }

  Future<void> createProduct({
    required String name,
    required String description,
    required String category,
    int? categoryId,
    required double price,
    required int stock,
    String? imageUrl,
    bool isActive = true,
  }) async {
    // Tao moi san pham vao products, ho tro ca category text va category_id.
    await supabase.from('products').insert({
      'name': name,
      'description': description,
      'category': category,
      'category_id': categoryId,
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
    int? categoryId,
    required double price,
    required int stock,
    String? imageUrl,
    bool isActive = true,
  }) async {
    // Cap nhat san pham theo id.
    await supabase
        .from('products')
        .update({
          'name': name,
          'description': description,
          'category': category,
          'category_id': categoryId,
          'price': price,
          'stock': stock,
          'image_url': imageUrl,
          'is_active': isActive,
        })
        .eq('id', id);
  }

  Future<void> deleteProduct(int id) async {
    // Xoa san pham theo id.
    await supabase.from('products').delete().eq('id', id);
  }
}
