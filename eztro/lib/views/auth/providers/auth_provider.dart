import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(null) {
    _init();
  }

  Future<void> _init() async {
    state = await AuthService.getCurrentUser();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await AuthService.login(username: username, password: password);
    if (res['status'] == 'success') {
      state = UserModel.fromJson(res);
    }
    return res;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final res = await AuthService.register(
      username: username,
      password: password,
      fullName: fullName,
      phone: phone,
    );
    if (res['status'] == 'success') {
      state = UserModel.fromJson(res);
    }
    return res;
  }

  Future<void> logout() async {
    await AuthService.logout();
    state = null;
  }

  Future<bool> updateRole(String role) async {
    if (state == null) return false;
    final success = await AuthService.updateRole(state!.id, role);
    if (success) {
      state = await AuthService.getCurrentUser();
    }
    return success;
  }
}
