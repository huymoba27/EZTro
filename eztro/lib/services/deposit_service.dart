import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'auth_service.dart';
import '../models/deposit_model.dart';

class DepositService {
  static String get baseUrl => '${ApiConstants.baseUrl}/deposits';

  // Lấy danh sách cọc
  static Future<List<DepositModel>> getDeposits(
    int houseId,
    String status, {
    int month = 0,
    int year = 0,
    int userId = 0,
    String role = 'landlord',
  }) async {
    try {
      int finalUserId = userId;
      String finalRole = role;
      int mHouseId = 0;

      if (userId == 0) {
        final user = await AuthService.getCurrentUser();
        if (user != null) {
          finalUserId = user.id;
          finalRole = user.role;
          mHouseId = user.managedHouseId ?? 0;
        }
      }

      final url =
          '$baseUrl/get_deposits.php?house_id=$houseId&status=$status&month=$month&year=$year&user_id=$finalUserId&role=$finalRole&managed_house_id=$mHouseId';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List)
              .map((item) => DepositModel.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi getDeposits: $e");
      return [];
    }
  }

  // Tạo phiếu cọc mới
  static Future<Map<String, dynamic>> createDeposit({
    required int houseId,
    required int roomId,
    required String customerName,
    required String customerPhone,
    required double depositAmount,
    required String depositDate,
    required String expectedMoveInDate,
    String note = "",
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.post(
        Uri.parse('$baseUrl/create_deposit.php'),
        headers: {...ApiConstants.headers, 'Content-Type': 'application/json'},
        body: json.encode({
          'house_id': houseId,
          'room_id': roomId,
          'user_id': user?.id ?? 0,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'deposit_amount': depositAmount,
          'deposit_date': depositDate,
          'expected_move_in_date': expectedMoveInDate,
          'note': note,
        }),
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'status': 'error', 'message': 'Lỗi kết nối'};
    }
  }

  static Future<Map<String, dynamic>> updateDeposit({
    required int depositId,
    required String customerName,
    required String customerPhone,
    required double depositAmount,
    required String depositDate,
    required String expectedMoveInDate,
    String note = "",
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.post(
        Uri.parse('$baseUrl/update_deposit.php'),
        headers: {...ApiConstants.headers, 'Content-Type': 'application/json'},
        body: json.encode({
          'deposit_id': depositId,
          'user_id': user?.id ?? 0,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'deposit_amount': depositAmount,
          'deposit_date': depositDate,
          'expected_move_in_date': expectedMoveInDate,
          'note': note,
        }),
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'status': 'error', 'message': 'Lỗi kết nối'};
    }
  }

  // Cập nhật trạng thái phiếu cọc
  static Future<Map<String, dynamic>> updateStatus(
    int id,
    String status, {
    double refundAmount = 0,
    String reason = "",
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      final userId = user?.id ?? 0;

      final response = await http.post(
        Uri.parse('$baseUrl/update_deposit_status.php'),
        headers: {...ApiConstants.headers, 'Content-Type': 'application/json'},
        body: json.encode({
          'id': id,
          'status': status,
          'refund_amount': refundAmount,
          'user_id': userId,
          'reason': reason,
        }),
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'status': 'error', 'message': 'Lỗi kết nối'};
    }
  }

  // Xóa phiếu cọc (Chỉ dành cho Landlord và khi phiếu đã bị Hủy)
  static Future<Map<String, dynamic>> deleteDeposit(int depositId) async {
    try {
      final user = await AuthService.getCurrentUser();
      final role = user?.role ?? 'landlord';

      final response = await http.post(
        Uri.parse('$baseUrl/delete_deposit.php'),
        headers: {...ApiConstants.headers, 'Content-Type': 'application/json'},
        body: json.encode({
          'deposit_id': depositId,
          'user_id': user?.id ?? 0,
          'role': role,
        }),
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {'status': 'error', 'message': 'Lỗi kết nối'};
    }
  }

  // Lấy chi tiết phiếu cọc
  static Future<DepositModel?> getDepositDetail(int id) async {
    try {
      final user = await AuthService.getCurrentUser();
      int userId = user?.id ?? 0;
      String role = user?.role ?? 'landlord';
      int mHouseId = user?.managedHouseId ?? 0;

      final url =
          '$baseUrl/get_deposits.php?id=$id&user_id=$userId&role=$role&managed_house_id=$mHouseId';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return DepositModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint("Lỗi getDepositDetail: $e");
      return null;
    }
  }

  // Lấy phiếu cọc theo room_id (cho tự điền thông tin khi chọn phòng đã cọc)
  static Future<DepositModel?> getDepositByRoom(int roomId) async {
    try {
      final user = await AuthService.getCurrentUser();
      int userId = user?.id ?? 0;
      String role = user?.role ?? 'landlord';

      final url =
          '$baseUrl/get_deposits.php?room_id=$roomId&user_id=$userId&role=$role';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          if (data['data'] is List) {
            if ((data['data'] as List).isNotEmpty) {
              return DepositModel.fromJson(data['data'][0]);
            }
          } else if (data['data'] is Map<String, dynamic>) {
            return DepositModel.fromJson(data['data']);
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint("Lỗi getDepositByRoom: $e");
      return null;
    }
  }

  // ═══════════════════════════════════════════
  // 🎯 TENANT DEPOSIT FLOW
  // ═══════════════════════════════════════════

  // Khách thuê tạo đơn đặt cọc + thanh toán PayOS
  static Future<Map<String, dynamic>> createTenantDeposit({
    required int userId,
    required int roomId,
    required int houseId,
    required String customerName,
    required String customerPhone,
    int? postId,
    String note = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create_tenant_deposit.php'),
        headers: {...ApiConstants.headers, 'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'room_id': roomId,
          'house_id': houseId,
          'post_id': postId,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'note': note,
        }),
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      debugPrint("Deposit API error: $e");
      return {'status': 'error', 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Lấy danh sách đặt cọc của khách theo user_id
  static Future<List<DepositModel>> getTenantDeposits(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_deposits.php?user_id=$userId&role=tenant'),
        headers: ApiConstants.headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List)
              .map((item) => DepositModel.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi getTenantDeposits: $e");
      return [];
    }
  }

  // Kiểm tra trạng thái đơn cọc (polling)
  static Future<DepositModel?> checkDepositStatus(int depositId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/check_deposit_status.php?deposit_id=$depositId'),
        headers: ApiConstants.headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return DepositModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint("Lỗi checkDepositStatus: $e");
      return null;
    }
  }

  // Gi giả lập thanh toán thành công (test only)
  static Future<Map<String, dynamic>> simulateDepositPayment(
    int depositId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/simulate_deposit_payment.php?deposit_id=$depositId',
        ),
        headers: ApiConstants.headers,
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      debugPrint("Simulate error: $e");
      return {'status': 'error', 'message': 'Lỗi: $e'};
    }
  }
}
