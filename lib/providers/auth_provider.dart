import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService) {
    // Lang nghe thay doi session Supabase (login/logout/refresh token).
    // Moi lan session doi se tai lai profile tu bang users.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      loadProfile();
    });
    loadProfile();
  }

  AppUser? userProfile;
  bool isLoading = false;
  String? error;
  late final StreamSubscription<AuthState> _authSub;

  bool get isLoggedIn => _authService.currentUser != null;
  bool get isAdmin => userProfile?.isAdmin ?? false;

  Future<void> loadProfile() async {
    try {
      // Lay thong tin nguoi dung dang nhap tu AuthService.getProfile()
      // (du lieu nguon: Supabase auth + bang public.users).
      isLoading = true;
      error = null;
      notifyListeners();
      userProfile = await _authService.getProfile();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Dang ky tai Supabase Auth, metadata kem full_name.
      isLoading = true;
      error = null;
      notifyListeners();
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      // Dang nhap bang email/password, sau do tai profile de cap nhat UI.
      isLoading = true;
      error = null;
      notifyListeners();
      await _authService.signIn(email: email, password: password);
      await loadProfile();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // Dang xuat session Supabase va xoa cache profile tren app.
    await _authService.signOut();
    userProfile = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String address,
    String? avatarUrl,
  }) async {
    try {
      // Upsert thong tin vao bang users, sau do load lai profile moi.
      isLoading = true;
      error = null;
      notifyListeners();
      await _authService.upsertProfile(
        fullName: fullName,
        phone: phone,
        address: address,
        avatarUrl: avatarUrl,
      );
      await loadProfile();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Doi mat khau theo luong: xac thuc lai mat khau cu -> cap nhat mat khau moi.
      isLoading = true;
      error = null;
      notifyListeners();
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}
