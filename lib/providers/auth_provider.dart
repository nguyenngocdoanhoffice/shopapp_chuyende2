import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService) {
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
