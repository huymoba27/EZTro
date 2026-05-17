import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'auth_service.dart';
import '../models/vehicle_model.dart';

class VehicleService {
  // 1. Lấy danh sách khách thuê kèm thông tin xe theo phòng
  // 1. Lấy danh sách khách thuê kèm thông tin xe (Lọc theo nhà hoặc phòng)
  static Future<List<Map<String, dynamic>>> getTenantsWithVehicles({int? houseId, int? roomId}) async {
    final user = await AuthService.getCurrentUser();
    final userId = user?.id ?? 0;
    final role = user?.role ?? 'landlord';
    final mHouseId = user?.managedHouseId ?? 0;
    
    String url = "${ApiConstants.vehicles}/get_vehicles.php?action=tenants&user_id=$userId&role=$role&managed_house_id=$mHouseId";
    if (houseId != null) url += "&house_id=$houseId";
    if (roomId != null) url += "&room_id=$roomId";
    
    final response = await http.get(Uri.parse(url));
    final data = json.decode(utf8.decode(response.bodyBytes));
    return List<Map<String, dynamic>>.from(data['data']);
  }

  // 2. Thêm xe mới (có ảnh xe)
  static Future<Map<String, dynamic>> addVehicle({
    required int tenantId, required String plate, required String type, File? image,
  }) async {
    final user = await AuthService.getCurrentUser();
    var request = http.MultipartRequest('POST', Uri.parse("${ApiConstants.vehicles}/save_vehicle.php"));
    request.fields.addAll({'action': 'save', 'user_id': (user?.id ?? 0).toString(), 'tenant_id': tenantId.toString(), 'license_plate': plate, 'vehicle_type': type});
    if (image != null) request.files.add(await http.MultipartFile.fromPath('vehicle_image', image.path));
    var response = await http.Response.fromStream(await request.send());
    return json.decode(utf8.decode(response.bodyBytes));
  }

  // 3. Cập nhật thông tin xe
  static Future<Map<String, dynamic>> updateVehicle({
    required int vehicleId, required int tenantId, required String plate, required String type, File? image,
  }) async {
    final user = await AuthService.getCurrentUser();
    var request = http.MultipartRequest('POST', Uri.parse("${ApiConstants.vehicles}/save_vehicle.php"));
    request.fields.addAll({'action': 'update', 'user_id': (user?.id ?? 0).toString(), 'id': vehicleId.toString(), 'tenant_id': tenantId.toString(), 'license_plate': plate, 'vehicle_type': type});
    if (image != null) request.files.add(await http.MultipartFile.fromPath('vehicle_image', image.path));
    var response = await http.Response.fromStream(await request.send());
    return json.decode(utf8.decode(response.bodyBytes));
  }

  // 4. Xóa xe
  static Future<Map<String, dynamic>> deleteVehicle({required int id}) async {
    final user = await AuthService.getCurrentUser();
    final response = await http.post(Uri.parse("${ApiConstants.vehicles}/save_vehicle.php"), body: {"action": "delete", "id": id.toString(), "user_id": (user?.id ?? 0).toString()});
    return json.decode(utf8.decode(response.bodyBytes));
  }

  // 5. Lấy danh sách phòng có sử dụng dịch vụ giữ xe
  static Future<List<Map<String, dynamic>>> getRoomsWithVehicleService({required int houseId}) async {
    final user = await AuthService.getCurrentUser();
    final userId = user?.id ?? 0;
    final role = user?.role ?? 'landlord';
    final mHouseId = user?.managedHouseId ?? 0;

    final response = await http.get(Uri.parse("${ApiConstants.vehicles}/get_vehicles.php?action=pending_rooms&house_id=$houseId&user_id=$userId&role=$role&managed_house_id=$mHouseId"));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return [];
  }

  // 6. Lấy danh sách phương tiện (Thông minh hóa phân quyền)
  static Future<List<VehicleModel>> getAllVehicles() async {
    try {
      int userId = 0;
      String role = 'landlord';
      int mHouseId = 0;

      // Tự động lấy Session
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        userId = user.id;
        role = user.role;
        mHouseId = user.managedHouseId ?? 0;
      }

      final url = "${ApiConstants.vehicles}/get_vehicles.php?user_id=$userId&role=$role&managed_house_id=$mHouseId";
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List).map((v) => VehicleModel.fromJson(v)).toList();
        }
      }
    } catch (e) {
      debugPrint("Lỗi getAllVehicles: $e");
    }
    return [];
  }

  // 7. Lấy danh sách nhà có người chưa đăng ký xe (Tối ưu hóa)
  static Future<List<Map<String, dynamic>>> getHousesWithUnregisteredVehicles() async {
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

      final url = "${ApiConstants.vehicles}/get_vehicles.php?action=unregistered_houses&user_id=$userId&role=$role&managed_house_id=$mHouseId";
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint("Lỗi getHousesWithUnregisteredVehicles: $e");
    }
    return [];
  }
}
