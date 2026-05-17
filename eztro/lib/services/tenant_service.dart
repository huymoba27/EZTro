import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/tenant_model.dart';
import 'api_constants.dart';
import 'auth_service.dart';

class TenantService {
  // 1. Lấy danh sách tất cả khách thuê (Thông minh hóa phân quyền)
  static Future<List<TenantModel>> getAllTenants({int? userId}) async {
    try {
      int finalId = userId ?? 0;
      String role = 'landlord';
      int mHouseId = 0;

      // Nếu truyền 1 (Legacy) hoặc null, tự động lấy từ Session
      if (userId == null || userId == 1) {
        final user = await AuthService.getCurrentUser();
        if (user != null) {
          finalId = user.id;
          role = user.role;
          mHouseId = user.managedHouseId ?? 0;
        }
      }

      final url = '${ApiConstants.tenants}/get_tenants.php?user_id=$finalId&role=$role&managed_house_id=$mHouseId';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success' && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => TenantModel.fromJson(item))
              .toList();
        }
      }
    } catch (e) { 
      debugPrint("Lỗi getAllTenants: $e"); 
    }
    return [];
  }

  // 2. Cập nhật thông tin khách thuê (có ảnh CCCD)
  static Future<Map<String, dynamic>> updateTenant({
    required int tenantId, required String tenantName, required String phone,
    required String gender, String? birthday, String? email, String? idCard,
    String? idCardDate, String? idCardPlace, String? address, File? imageFront, File? imageBack,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      var request = http.MultipartRequest('POST', Uri.parse("${ApiConstants.tenants}/update_tenant.php"));
      request.headers.addAll(ApiConstants.headers);
      request.fields.addAll({
        'user_id': (user?.id ?? 0).toString(),
        'tenant_id': tenantId.toString(), 'tenant_name': tenantName, 'phone': phone,
        'gender': gender, 'birthday': birthday ?? "", 'email': email ?? "",
        'id_card': idCard ?? "", 'id_card_date': idCardDate ?? "",
        'id_card_place': idCardPlace ?? "", 'address': address ?? "",
      });
      if (imageFront != null) request.files.add(await http.MultipartFile.fromPath('cccd_front', imageFront.path));
      if (imageBack != null) request.files.add(await http.MultipartFile.fromPath('cccd_back', imageBack.path));
      var resp = await http.Response.fromStream(await request.send());
      return json.decode(utf8.decode(resp.bodyBytes));
    } catch (e) { return {"status": "error", "message": e.toString()}; }
  }

  // 3. Xóa khách thuê (Đã chuẩn hóa)
  static Future<Map<String, dynamic>> deleteTenant({required int tenantId}) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.post(
        Uri.parse("${ApiConstants.tenants}/delete_tenant.php"),
        headers: ApiConstants.headers,
        body: {"tenant_id": tenantId.toString(), "user_id": (user?.id ?? 0).toString()},
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) { return {"status": "error", "message": e.toString()}; }
  }

  // 4. Lấy chi tiết khách thuê (Đã chuẩn hóa)
  static Future<Map<String, dynamic>?> getTenantDetail({required int tenantId}) async {
    try {
      final user = await AuthService.getCurrentUser();
      final userId = user?.id ?? 0;
      final role = user?.role ?? 'landlord';
      final mHouseId = user?.managedHouseId ?? 0;

      final url = '${ApiConstants.tenants}/get_tenants.php?id=$tenantId&user_id=$userId&role=$role&managed_house_id=$mHouseId';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') return data['data'];
      }
    } catch (e) { debugPrint(e.toString()); }
    return null;
  }

  // 5. Thêm thành viên mới vào phòng (Bản đầy đủ tham số)
  static Future<Map<String, dynamic>> addMember({
    required int roomId,
    required String tenantName,
    required String phone,
    required String gender,
    String? birthday,
    String? email,
    String? idCard,
    String? idCardDate,
    String? idCardPlace,
    String? address,
    File? imageFront,
    File? imageBack,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      var request = http.MultipartRequest('POST', Uri.parse("${ApiConstants.tenants}/add_member.php"));
      request.headers.addAll(ApiConstants.headers);

      request.fields.addAll({
        'user_id': (user?.id ?? 0).toString(),
        'room_id': roomId.toString(),
        'tenant_name': tenantName,
        'phone': phone,
        'gender': gender,
        'birthday': birthday ?? "",
        'email': email ?? "",
        'id_card': idCard ?? "",
        'id_card_date': idCardDate ?? "",
        'id_card_place': idCardPlace ?? "",
        'address': address ?? "",
      });

      if (imageFront != null) {
        request.files.add(await http.MultipartFile.fromPath('cccd_front', imageFront.path));
      }
      if (imageBack != null) {
        request.files.add(await http.MultipartFile.fromPath('cccd_back', imageBack.path));
      }

      var resp = await http.Response.fromStream(await request.send());
      return json.decode(utf8.decode(resp.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối API: ${e.toString()}"};
    }
  }
}
