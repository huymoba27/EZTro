import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import '../models/house_model.dart';
import 'auth_service.dart';

class HouseService {
  // 1. Lấy danh sách nhà (Thông minh hóa phân quyền)
  static Future<List<HouseModel>> getHouses({
    int? userId,
    String? role,
    int? managedHouseId,
  }) async {
    try {
      int finalId = userId ?? 0;
      String finalRole = role ?? 'landlord';
      int finalMHouseId = managedHouseId ?? 0;

      // Chỉ fetch user nếu không truyền tham số vào
      if (userId == null) {
        final user = await AuthService.getCurrentUser();
        if (user != null) {
          finalId = user.id;
          finalRole = user.role;
          finalMHouseId = user.managedHouseId ?? 0;
        }
      }

      final url =
          "${ApiConstants.houses}/get_houses.php?user_id=$finalId&role=$finalRole&managed_house_id=$finalMHouseId";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List)
              .map((json) => HouseModel.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Lỗi getHouses: $e");
    }
    return [];
  }

  // 2. Thêm nhà mới (có upload ảnh)
  static Future<Map<String, dynamic>> addHouse({
    required int userId,
    required String name,
    required String city,
    required String ward,
    required String addressDetail,
    required List<int> selectedAmenities,
    File? imageFile,
    double? latitude,
    double? longitude,
    double? totalArea,
    int? floors,
    String? ownerName,
    String? ownerPhone,
  }) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${ApiConstants.houses}/add_house.php"),
      );
      request.fields['user_id'] = userId.toString();
      request.fields['house_name'] = name;
      request.fields['city'] = city;
      request.fields['ward'] = ward;
      request.fields['address_detail'] = addressDetail;
      request.fields['amenities'] = selectedAmenities.toSet().toList().join(',');
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      if (totalArea != null) {
        request.fields['total_area'] = totalArea.toString();
      }
      if (floors != null) request.fields['floors'] = floors.toString();
      if (ownerName != null) request.fields['owner_name'] = ownerName;
      if (ownerPhone != null) request.fields['owner_phone'] = ownerPhone;

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      return json.decode(utf8.decode(responseData));
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  // 3. Cập nhật thông tin nhà
  static Future<Map<String, dynamic>> updateHouse({
    required int houseId,
    required String name,
    required String city,
    required String ward,
    required String addressDetail,
    required List<int> selectedAmenities,
    File? imageFile,
    double? latitude,
    double? longitude,
    double? totalArea,
    int? floors,
    String? ownerName,
    String? ownerPhone,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.houses}/update_house.php'),
      );
      request.fields['user_id'] = (user?.id ?? 0).toString();
      request.fields['id'] = houseId.toString();
      request.fields['house_name'] = name;
      request.fields['city'] = city;
      request.fields['ward'] = ward;
      request.fields['address_detail'] = addressDetail;
      request.fields['amenity_ids'] = selectedAmenities.toSet().toList().join(',');
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      if (totalArea != null) {
        request.fields['total_area'] = totalArea.toString();
      }
      if (floors != null) request.fields['floors'] = floors.toString();
      if (ownerName != null) request.fields['owner_name'] = ownerName;
      if (ownerPhone != null) request.fields['owner_phone'] = ownerPhone;

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      return json.decode(utf8.decode(responseData));
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // 4. Xóa nhà
  static Future<Map<String, dynamic>> deleteHouse(int houseId) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.post(
        Uri.parse("${ApiConstants.houses}/delete_house.php"),
        body: {"house_id": houseId.toString(), "user_id": (user?.id ?? 0).toString()},
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối: $e"};
    }
  }

  // 5. Lấy danh sách nhà đã có hợp đồng (Thông minh hóa)
  static Future<List<HouseModel>> getHousesWithContracts({
    int? userId,
    String? role,
    int? managedHouseId,
  }) async {
    try {
      int finalId = userId ?? 0;
      String finalRole = role ?? 'landlord';
      int finalMHouseId = managedHouseId ?? 0;

      if (userId == null) {
        final user = await AuthService.getCurrentUser();
        if (user != null) {
          finalId = user.id;
          finalRole = user.role;
          finalMHouseId = user.managedHouseId ?? 0;
        }
      }

      final url =
          "${ApiConstants.houses}/get_houses.php?user_id=$finalId&role=$finalRole&managed_house_id=$finalMHouseId&with_contracts=true";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List)
              .map((e) => HouseModel.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Lỗi getHousesWithContracts: $e");
    }
    return [];
  }

  // 6. Lấy danh sách toàn bộ tiện ích từ DB
  static Future<List<Map<String, dynamic>>> getAmenities() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.houses}/get_all_amenities.php"),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("Lỗi getAmenities: $e");
    }
    return [];
  }
}
