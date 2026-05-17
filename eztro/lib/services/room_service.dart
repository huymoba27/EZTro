import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/room_model.dart';
import 'api_constants.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class RoomService {
  // 1. Lấy danh sách phòng (Thông minh hóa phân quyền)
  static Future<List<RoomModel>> getRooms({
    int? houseId,
    int? userId,
    String? role,
    int? managedHouseId,
  }) async {
    try {
      int finalHouseId = houseId ?? 0;
      int finalId = userId ?? 0;
      String finalRole = role ?? 'landlord';
      int finalMHouseId = managedHouseId ?? 0;

      // Tự động lấy Session nếu không truyền vào
      if (userId == null) {
        final user = await AuthService.getCurrentUser();
        if (user != null) {
          finalId = user.id;
          finalRole = user.role;
          finalMHouseId = user.managedHouseId ?? 0;
        }
      }

      final url =
          "${ApiConstants.rooms}/get_rooms.php?house_id=$finalHouseId&user_id=$finalId&role=$finalRole&managed_house_id=$finalMHouseId";
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List).map((json) => RoomModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint("Lỗi getRooms: $e");
    }
    return [];
  }

  // 2. Lấy chi tiết một phòng (Trả về Map chi tiết)
  static Future<Map<String, dynamic>> getRoomDetail({required int roomId}) async {
    try {
      final user = await AuthService.getCurrentUser();
      final userId = user?.id ?? 0;
      final role = user?.role ?? 'landlord';
      final mHouseId = user?.managedHouseId ?? 0;

      final url = "${ApiConstants.rooms}/get_rooms.php?id=$roomId&user_id=$userId&role=$role&managed_house_id=$mHouseId";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') return data['data'];
      }
    } catch (e) {
      debugPrint("Lỗi getRoomDetail: $e");
    }
    return {};
  }

  // 3. Lấy danh sách tất cả phòng trống (Thông minh hóa phân quyền)
  static Future<List<RoomModel>> getAvailableRooms({int? userId}) async {
    try {
      int finalId = userId ?? 0;
      String role = 'landlord';
      int mHouseId = 0;

      // Tự động lấy Session
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        finalId = user.id;
        role = user.role;
        mHouseId = user.managedHouseId ?? 0;
      }

      final url = "${ApiConstants.rooms}/get_rooms.php?user_id=$finalId&role=$role&managed_house_id=$mHouseId&status=available";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data is List) {
           return data.map((e) => RoomModel.fromJson(e)).toList();
        } else if (data['status'] == 'success') {
           return (data['data'] as List).map((e) => RoomModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint("Lỗi availableRooms: $e");
    }
    return [];
  }

  // 4. Thêm phòng mới (có upload nhiều ảnh)
  static Future<Map<String, dynamic>> addRoom({
    required int houseId,
    required String roomName,
    required double price,
    required double deposit,
    required double area,
    required int maxTenants,
    required List<File> imageFiles,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      var request = http.MultipartRequest("POST", Uri.parse("${ApiConstants.rooms}/add_room.php"));
      request.fields['user_id'] = (user?.id ?? 0).toString();
      request.fields['house_id'] = houseId.toString();
      request.fields['room_name'] = roomName;
      request.fields['price'] = price.toString();
      request.fields['deposit'] = deposit.toString();
      request.fields['area'] = area.toString();
      request.fields['max_tenants'] = maxTenants.toString();

      for (var file in imageFiles) {
        request.files.add(await http.MultipartFile.fromPath('images[]', file.path));
      }

      var response = await http.Response.fromStream(await request.send());
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối: $e"};
    }
  }

  // 5. Cập nhật thông tin phòng
  static Future<Map<String, dynamic>> updateRoom({
    required int roomId,
    required int houseId,
    required String roomName,
    required double price,
    required double deposit,
    required double area,
    required int maxTenants,
    required List<File> imageFiles,
    List<String>? deletedImagePaths,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      var request = http.MultipartRequest("POST", Uri.parse("${ApiConstants.rooms}/update_room.php"));
      request.fields['user_id'] = (user?.id ?? 0).toString();
      request.fields['room_id'] = roomId.toString();
      request.fields['house_id'] = houseId.toString();
      request.fields['room_name'] = roomName;
      request.fields['price'] = price.toString();
      request.fields['deposit'] = deposit.toString();
      request.fields['area'] = area.toString();
      request.fields['max_tenants'] = maxTenants.toString();

      if (deletedImagePaths != null && deletedImagePaths.isNotEmpty) {
        request.fields['deleted_images'] = deletedImagePaths.join(',');
      }

      for (var file in imageFiles) {
        request.files.add(await http.MultipartFile.fromPath('images[]', file.path));
      }

      var response = await http.Response.fromStream(await request.send());
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối: $e"};
    }
  }

  // 6. Xóa phòng
  static Future<Map<String, dynamic>> deleteRoom({required int roomId}) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.post(
        Uri.parse("${ApiConstants.rooms}/delete_room.php"),
        body: {"room_id": roomId.toString(), "user_id": (user?.id ?? 0).toString()},
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi: $e"};
    }
  }

  // 7. Lấy danh sách phòng đã có người ở (Thông minh hóa phân quyền)
  static Future<List<RoomModel>> getOccupiedRooms({int? userId}) async {
    try {
      int finalId = userId ?? 0;
      String role = 'landlord';
      int mHouseId = 0;

      // Tự động lấy Session
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        finalId = user.id;
        role = user.role;
        mHouseId = user.managedHouseId ?? 0;
      }

      final url = "${ApiConstants.rooms}/get_rooms.php?user_id=$finalId&role=$role&managed_house_id=$mHouseId&status=occupied";
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success' && data['data'] != null) {
          return (data['data'] as List).map((json) => RoomModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint("Lỗi getOccupiedRooms: $e");
    }
    return [];
  }

  // 8. Lấy danh sách phòng đã có người ở theo từng nhà cụ thể (Đã chuẩn hóa)
  static Future<List<RoomModel>> getOccupiedRoomsByHouse({required int houseId}) async {
    try {
      final user = await AuthService.getCurrentUser();
      final userId = user?.id ?? 0;
      final role = user?.role ?? 'landlord';
      final mHouseId = user?.managedHouseId ?? 0;

      final response = await http.get(
        Uri.parse("${ApiConstants.rooms}/get_rooms.php?house_id=$houseId&status=occupied&user_id=$userId&role=$role&managed_house_id=$mHouseId")
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List).map((json) => RoomModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint("Lỗi getOccupiedRoomsByHouse: $e");
    }
    return [];
  }

  // 9. Lấy danh sách phòng ĐANG Ở nhưng CÒN CHỖ (Dành cho thêm thành viên)
  static Future<List<RoomModel>> getRoomsWithSpace() async {
    try {
      final user = await AuthService.getCurrentUser();
      final userId = user?.id ?? 0;
      final role = user?.role ?? 'landlord';
      final mHouseId = user?.managedHouseId ?? 0;

      final url = "${ApiConstants.rooms}/get_rooms.php?status=has_space&user_id=$userId&role=$role&managed_house_id=$mHouseId";
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List).map((json) => RoomModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint("Lỗi getRoomsWithSpace: $e");
    }
    return [];
  }

  // 10. Lấy chỉ số điện nước mới nhất của phòng
  static Future<Map<String, dynamic>?> getLatestReadings(int roomId) async {
    try {
      final url = "${ApiConstants.rooms}/get_latest_readings.php?room_id=$roomId";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') return data['data'];
      }
    } catch (e) {
      debugPrint("Lỗi getLatestReadings: $e");
    }
    return null;
  }
}
