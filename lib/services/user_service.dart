import '../models/app_user.dart';
import '../supabase_client.dart';

class UserService {
  Future<List<AppUser>> getUsers() async {
    final data =
        await supabase
                .from('users')
                .select()
                .order('created_at', ascending: false)
            as List<dynamic>;
    return data
        .map((item) => AppUser.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<AppUser> getUserById(String id) async {
    final data = await supabase.from('users').select().eq('id', id).single();
    return AppUser.fromMap(data);
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    await supabase.from('users').update({'role': role}).eq('id', userId);
  }
}
