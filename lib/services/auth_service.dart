import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../supabase_client.dart';

class AuthService {
  User? get currentUser => supabase.auth.currentUser;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<AppUser?> getProfile() async {
    final user = currentUser;
    if (user == null) {
      return null;
    }

    final data = await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return AppUser.fromMap({...data, 'email': user.email ?? ''});
  }

  Future<void> upsertProfile({
    required String fullName,
    required String phone,
    required String address,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    await supabase.from('users').upsert({
      'id': user.id,
      'full_name': fullName,
      'phone': phone,
      'address': address,
      'avatar_url': avatarUrl,
      'email': user.email,
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null || user.email == null) {
      throw Exception('Not authenticated');
    }

    await supabase.auth.signInWithPassword(
      email: user.email!,
      password: currentPassword,
    );

    await supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
