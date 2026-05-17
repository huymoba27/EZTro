import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import '../models/service_model.dart';
import 'auth_service.dart';

class ServiceManageService {
  // 1. Lấy danh sách dịch vụ của một nhà cụ thể (Thông minh hóa phân quyền)
  static Future<List<ServiceModel>> getServices({required int houseId}) async {
    try {
      int userId = 0;
      String role = 'landlord';
      int mHouseId = 0;

      final user = await AuthService.getCurrentUser();
      if (user != null) {
        userId = user.id;
        role = user.role;
        mHouseId = user.managedHouseId ?? 0;
      }

      final url = "${ApiConstants.services}/get_services.php?house_id=$houseId&user_id=$userId&role=$role&managed_house_id=$mHouseId";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List).map((json) => ServiceModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint("Lỗi getServices: $e");
    }
    return [];
  }

  // 2. Thêm dịch vụ mới và áp dụng cho danh sách nhà
  static Future<Map<String, dynamic>> addService({
    required String name,
    required double price,
    required String unit,
    required String charge_type,
    required String service_type,
    required List<int> houseIds,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.post(
        Uri.parse("${ApiConstants.services}/save_service.php"),
        body: {
          "action": "save",
          "user_id": (user?.id ?? 0).toString(),
          "service_name": name,
          "price": price.toString(),
          "unit": unit,
          "charge_type": charge_type,
          "service_type": service_type,
          "house_ids": jsonEncode(houseIds),
        },
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối: $e"};
    }
  }

  // 3. Cập nhật dịch vụ
  static Future<Map<String, dynamic>> updateService({
    required int id,
    required String name,
    required double price,
    required String unit,
    required String charge_type,
    required String service_type,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.post(
        Uri.parse("${ApiConstants.services}/save_service.php"),
        body: {
          "action": "update",
          "user_id": (user?.id ?? 0).toString(),
          "id": id.toString(),
          "service_name": name,
          "price": price.toString(),
          "unit": unit,
          "charge_type": charge_type,
          "service_type": service_type,
        },
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối: $e"};
    }
  }

  // 4. Xóa dịch vụ
  static Future<Map<String, dynamic>> deleteService(int id) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.post(
        Uri.parse("${ApiConstants.services}/save_service.php"),
        body: {"action": "delete", "id": id.toString(), "user_id": (user?.id ?? 0).toString()},
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối: $e"};
    }
  }
}
