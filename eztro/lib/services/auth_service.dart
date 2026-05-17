import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_constants.dart';

class AuthService {
  static const String _userKey = 'user_data';
  static UserModel? _cachedUser;

  // 🎯 Đăng ký tài khoản truyền thống
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.serverUrl}/backend_api/auth/register.php"),
        body: {
          'username': username,
          'password': password,
          'full_name': fullName,
          'phone': phone,
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, json.encode(data));
          _cachedUser = UserModel.fromJson(data);
          return data;
        } else {
          return {"status": "error", "message": data['message'] ?? 'Lỗi không xác định'};
        }
      }
      return {"status": "error", "message": "Lỗi máy chủ (HTTP ${response.statusCode})"};
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối mạng: $e"};
    }
  }

  // 🎯 Đăng nhập truyền thống
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.serverUrl}/backend_api/auth/login.php"),
        body: {
          'username': username,
          'password': password,
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, json.encode(data));
          _cachedUser = UserModel.fromJson(data);
          return data;
        } else {
          return {"status": "error", "message": data['message'] ?? 'Sai tài khoản hoặc mật khẩu'};
        }
      }
      return {"status": "error", "message": "Lỗi máy chủ (HTTP ${response.statusCode})"};
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối mạng: $e"};
    }
  }

  // 🎯 Đăng xuất
  static Future<void> logout() async {
    _cachedUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // 🎯 Lấy thông tin user hiện tại
  static Future<UserModel?> getCurrentUser() async {
    if (_cachedUser != null) return _cachedUser;
    
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      _cachedUser = UserModel.fromJson(json.decode(userJson));
      return _cachedUser;
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey);
  }

  // 🎯 Cập nhật vai trò (Role Selection)
  static Future<bool> updateRole(int userId, String role) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.serverUrl}/backend_api/auth/update_role.php"),
        body: {
          'user_id': userId.toString(),
          'role': role,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          final userJson = prefs.getString(_userKey);
          if (userJson != null) {
            Map<String, dynamic> userData = json.decode(userJson);
            userData['role'] = role;
            await prefs.setString(_userKey, json.encode(userData));
            _cachedUser = UserModel.fromJson(userData); // Update cache
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getManagersAndLandlords() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiConstants.serverUrl}/backend_api/auth/get_managers_landlords.php",
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching managers: $e");
    }
    return [];
  }
}
