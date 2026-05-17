import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/contract_model.dart';
import 'api_constants.dart';
import 'auth_service.dart';

class ContractService {
  // 1. Lấy danh sách hợp đồng (Thông minh hóa phân quyền)
  static Future<List<ContractModel>> getContracts({
    int houseId = 0,
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
          "${ApiConstants.contracts}/get_contracts.php?house_id=$houseId&user_id=$finalId&role=$finalRole&managed_house_id=$finalMHouseId";
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(utf8.decode(response.bodyBytes));
        if (result['status'] == 'success' && result['data'] != null) {
          return (result['data'] as List)
              .map((item) => ContractModel.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Lỗi getContracts: $e");
    }
    return [];
  }

  // 2. Tạo hợp đồng mới (Ký hợp đồng cho khách mới)
  static Future<Map<String, dynamic>> createContract({
    required int roomId,
    required String customerName,
    required String phone,
    required String password,
    String? birthday,
    String? gender,
    String? email,
    required String idCard,
    String? idCardDate,
    String? idCardPlace,
    String? address,
    required double price,
    required double deposit,
    required String startDate,
    required String endDate,
    required String createDate,
    required int paymentDay,
    required List<int> serviceIds,
    required int startElectric, 
    required int startWater,
    int? depositId,
    File? imageFront,
    File? imageBack,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("${ApiConstants.contracts}/create_contract.php"));

      request.fields.addAll({
        "room_id": roomId.toString(),
        "customer_name": customerName,
        "customer_phone": phone,
        "customer_pass": password,
        "birthday": birthday ?? "",
        "gender": gender ?? "Nam",
        "email": email ?? "",
        "id_card": idCard,
        "id_card_date": idCardDate ?? "",
        "id_card_place": idCardPlace ?? "",
        "address": address ?? "",
        "rent_price": price.toString(),
        "deposit_amount": deposit.toString(),
        "start_date": startDate,
        "end_date": endDate,
        "create_date": createDate,
        "payment_day": paymentDay.toString(),
        "service_ids": json.encode(serviceIds),
        "start_electric": startElectric.toString(),
        "start_water": startWater.toString(),
        "deposit_id": depositId?.toString() ?? "0",
        "user_id": (await AuthService.getCurrentUser())?.id.toString() ?? "0",
      });

      if (imageFront != null) request.files.add(await http.MultipartFile.fromPath('cccd_front', imageFront.path));
      if (imageBack != null) request.files.add(await http.MultipartFile.fromPath('cccd_back', imageBack.path));

      var response = await http.Response.fromStream(await request.send());
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối API: $e"};
    }
  }

  // 3. Cập nhật hợp đồng (Sửa giá, tiền cọc, dịch vụ...)
  static Future<Map<String, dynamic>> updateContract({
    required int roomId,
    required int contractId,
    required double price,
    required double deposit,
    required int paymentDay,
    required int startElectric,
    required int startWater,
    required List<int> serviceIds,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      final userId = user?.id ?? 0;

      final response = await http.post(
        Uri.parse("${ApiConstants.contracts}/manage_contract.php"),
        body: {
          'action': 'update',
          'room_id': roomId.toString(),
          'contract_id': contractId.toString(),
          'price': price.toString(),
          'deposit': deposit.toString(),
          'payment_day': paymentDay.toString(),
          'start_electric': startElectric.toString(),
          'start_water': startWater.toString(),
          'service_ids': json.encode(serviceIds),
          'user_id': userId.toString(),
        },
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  // 4. Xóa hợp đồng (Khi khách trả phòng hoặc xóa nhầm)
  static Future<Map<String, dynamic>> deleteContract({required int roomId, required int contractId}) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.contracts}/manage_contract.php"),
        body: {
          "action": "delete",
          "contract_id": contractId.toString(),
          "user_id": (await AuthService.getCurrentUser())?.id.toString() ?? "0",
        },
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối API: $e"};
    }
  }

  // 5. Lấy chi tiết hợp đồng
  static Future<Map<String, dynamic>> getContractDetail({required int contractId}) async {
    try {
      final user = await AuthService.getCurrentUser();
      final userId = user?.id ?? 0;
      final role = user?.role ?? 'landlord';
      final mHouseId = user?.managedHouseId ?? 0;

      final url = "${ApiConstants.contracts}/get_contracts.php?id=$contractId&user_id=$userId&role=$role&managed_house_id=$mHouseId";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') return data['data'];
      }
    } catch (e) {
      debugPrint("Lỗi getContractDetail: $e");
    }
    return {};
  }

  // 6. Lấy bản tính thanh lý hợp đồng
  static Future<Map<String, dynamic>> getSettlementPreview(int contractId) async {
    try {
      final response = await http.get(Uri.parse("${ApiConstants.contracts}/get_settlement_preview.php?contract_id=$contractId"));
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối API: $e"};
    }
  }

  // 7. Thực hiện thanh lý hợp đồng
  static Future<Map<String, dynamic>> terminateContract({
    required int contractId,
    required double penalty,
    required double damage,
    required double cleaning,
    String reason = "",
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      final userId = user?.id ?? 0;

      final body = <String, dynamic>{
        "contract_id": contractId,
        "user_id": userId,
        "penalty_amount": penalty,
        "damage_amount": damage,
        "cleaning_fee": cleaning,
        "reason": reason,
      };

      final response = await http.post(
        Uri.parse("${ApiConstants.contracts}/terminate_contract.php"),
        headers: {
          ...ApiConstants.headers,
          "Content-Type": "application/json",
        },
        body: json.encode(body),
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối API: $e"};
    }
  }
}