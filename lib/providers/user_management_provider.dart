import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';

class UserManagementProvider extends ChangeNotifier {
  final UserService _userService;

  UserManagementProvider(this._userService);

  List<AppUser> users = [];
  bool isLoading = false;
  String? error;

  Future<void> loadUsers() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      users = await _userService.getUsers();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<AppUser?> getUserDetail(String userId) async {
    try {
      return await _userService.getUserById(userId);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    await _userService.updateUserRole(userId: userId, role: role);
    await loadUsers();
  }
}
