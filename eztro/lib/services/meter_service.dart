import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_constants.dart';
import '../models/meter_model.dart';
import '../models/house_model.dart';

class MeterService {
  // 1. Lấy chỉ số cũ (lần đọc gần nhất)
  static Future<Map<String, dynamic>> getLastReading(int roomId) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.get(
        Uri.parse(
          "${ApiConstants.meters}/get_meters.php?action=last_reading&room_id=$roomId&user_id=${user?.id ?? 0}",
        ),
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getLatestRoomReading(int roomId) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.get(
        Uri.parse(
          "${ApiConstants.meters}/get_meters.php?action=room_latest_reading&room_id=$roomId&user_id=${user?.id ?? 0}",
        ),
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  // 2. Lưu chỉ số chốt mới
  static Future<Map<String, dynamic>> saveMeterReading(
    MeterModel meter, {
    File? electricImage,
    File? waterImage,
  }) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${ApiConstants.meters}/save_meter.php"),
      );
      final user = await AuthService.getCurrentUser();

      final body = meter.toJson();
      body.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      request.fields['action'] = 'save';
      request.fields['user_id'] = (user?.id ?? 0).toString();
      request.fields['old_e'] = meter.oldElectric.toString();
      request.fields['new_e'] = meter.newElectric.toString();
      request.fields['old_w'] = meter.oldWater.toString();
      request.fields['new_w'] = meter.newWater.toString();
      request.fields['month'] = meter.billingMonth.toString();
      request.fields['year'] = meter.billingYear.toString();

      if (electricImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'electric_image',
            electricImage.path,
          ),
        );
      }
      if (waterImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('water_image', waterImage.path),
        );
      }

      var response = await http.Response.fromStream(await request.send());
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  // 3. Lấy trạng thái chốt số của cả nhà trong tháng
  static Future<List<Map<String, dynamic>>> getMeterStatusByHouse({
    required int houseId,
    required int month,
    required int year,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      final userId = user?.id ?? 0;
      final role = user?.role ?? 'landlord';
      final mHouseId = user?.managedHouseId ?? 0;
      final response = await http.get(
        Uri.parse(
          "${ApiConstants.meters}/get_meters.php?action=status&house_id=$houseId&month=$month&year=$year&user_id=$userId&role=$role&managed_house_id=$mHouseId",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint("Error getMeterStatusByHouse: $e");
    }
    return [];
  }

  // 4. Lấy danh sách các phòng chưa chốt số
  static Future<List<Map<String, dynamic>>> getPendingRooms({
    required int houseId,
    required int month,
    required int year,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.get(
        Uri.parse(
          "${ApiConstants.meters}/get_meters.php?action=pending_rooms&house_id=$houseId&month=$month&year=$year&user_id=${user?.id ?? 0}",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint("Lỗi getPendingRooms: $e");
    }
    return [];
  }

  // 5. Cập nhật chỉ số đã chốt
  static Future<Map<String, dynamic>> updateMeterReading(
    MeterModel meter, {
    File? electricImage,
    File? waterImage,
  }) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${ApiConstants.meters}/save_meter.php"),
      );
      final user = await AuthService.getCurrentUser();
      request.fields['action'] = 'update';
      request.fields['user_id'] = (user?.id ?? 0).toString();
      request.fields['id'] = meter.id.toString();
      request.fields['new_e'] = meter.newElectric.toString();
      request.fields['new_w'] = meter.newWater.toString();

      if (electricImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'electric_image',
            electricImage.path,
          ),
        );
      }
      if (waterImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('water_image', waterImage.path),
        );
      }

      var response = await http.Response.fromStream(await request.send());
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  // 6. Xóa bản ghi chốt số
  static Future<Map<String, dynamic>> deleteMeterReading(int id) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.post(
        Uri.parse("${ApiConstants.meters}/save_meter.php"),
        body: {
          "action": "delete",
          "id": id.toString(),
          "user_id": (user?.id ?? 0).toString(),
        },
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  // 7. Lấy danh sách nhà kèm số lượng phòng chưa chốt số
  static Future<List<HouseModel>> getHousesWithPending({
    int? userId,
    required int month,
    required int year,
  }) async {
    try {
      int finalId = userId ?? 0;
      String role = 'landlord';
      int mHouseId = 0;

      final user = await AuthService.getCurrentUser();
      if (user != null) {
        finalId = user.id;
        role = user.role;
        mHouseId = user.managedHouseId ?? 0;
      }

      final url =
          "${ApiConstants.meters}/get_meters.php?action=pending_houses&user_id=$finalId&role=$role&managed_house_id=$mHouseId&month=$month&year=$year";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        if (data['status'] == 'success') {
          List list = data['data'];
          return list.map((json) => HouseModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint("Lỗi getHousesWithPending: $e");
    }
    return [];
  }
}
