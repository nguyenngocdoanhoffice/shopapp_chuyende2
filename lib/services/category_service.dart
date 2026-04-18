import '../models/category.dart';
import '../supabase_client.dart';

class CategoryService {
  Future<List<Category>> getCategories() async {
    final data =
        await supabase
                .from('categories')
                .select()
                .order('name', ascending: true)
            as List<dynamic>;
    return data
        .map((item) => Category.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCategory({
    required String name,
    required String description,
  }) async {
    await supabase.from('categories').insert({
      'name': name,
      'description': description,
    });
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    required String description,
  }) async {
    await supabase
        .from('categories')
        .update({'name': name, 'description': description})
        .eq('id', id);
  }

  Future<void> deleteCategory(int id) async {
    await supabase.from('categories').delete().eq('id', id);
  }
}
