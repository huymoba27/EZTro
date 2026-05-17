import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/invoice_model.dart';
import 'api_constants.dart';
import 'auth_service.dart';
import '../models/house_model.dart';

class InvoiceService {
  // 1. Lấy danh sách phòng đã sẵn sàng để lập hóa đơn
  static Future<List<Map<String, dynamic>>> getRoomsReadyToBill({
    required int houseId,
    required int month,
    required int year,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.get(
        Uri.parse(
          "${ApiConstants.invoices}/get_invoices.php?action=rooms_ready&house_id=$houseId&month=$month&year=$year&user_id=${user?.id ?? 0}",
        ),
        headers: ApiConstants.headers,
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return List<Map<String, dynamic>>.from(data['data']);
    } catch (e) {
      return [];
    }
  }

  // 2. Lấy bản xem trước (Summary) hóa đơn trước khi tạo
  static Future<Map<String, dynamic>> getBillSummary(
    dynamic roomId,
    int month,
    int year,
  ) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.get(
        Uri.parse(
          "${ApiConstants.invoices}/get_invoices.php?action=summary&room_id=$roomId&month=$month&year=$year&user_id=${user?.id ?? 0}",
        ),
        headers: ApiConstants.headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Không thể kết nối server"};
    }
  }

  // 3. Lấy danh sách hóa đơn (Thông minh hóa phân quyền)
  static Future<List<InvoiceModel>> getInvoices({int? houseId}) async {
    try {
      int finalId = houseId ?? 0;
      int userId = 0;
      String role = 'landlord';
      int mHouseId = 0;
      int? currentRoomId;

      final user = await AuthService.getCurrentUser();
      if (user != null) {
        userId = user.id;
        role = user.role;
        mHouseId = user.managedHouseId ?? 0;
        currentRoomId = user.roomId;
      }

      String url =
          "${ApiConstants.invoices}/get_invoices.php?house_id=$finalId&user_id=$userId&role=$role&managed_house_id=$mHouseId";
      if (role == 'tenant' && currentRoomId != null) {
        url += "&room_id=$currentRoomId";
      }
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success' && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => InvoiceModel.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi getInvoices: $e");
      return [];
    }
  }

  // 4. Cập nhật trạng thái hóa đơn (Thanh toán)
  static Future<Map<String, dynamic>> updateInvoiceStatus(
    dynamic invoiceId,
    String status, {
    String reason = "",
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      final role = user?.role ?? 'landlord';
      final userId = user?.id ?? 0;

      final response = await http.post(
        Uri.parse("${ApiConstants.invoices}/update_invoice_status.php"),
        headers: ApiConstants.headers,
        body: {
          "invoice_id": invoiceId.toString(),
          "status": status,
          "role": role,
          "user_id": userId.toString(),
          "reason": reason,
        },
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối: $e"};
    }
  }

  // 5. Xóa hóa đơn
  static Future<Map<String, dynamic>> deleteInvoice(dynamic invoiceId) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.post(
        Uri.parse("${ApiConstants.invoices}/delete_invoice.php"),
        headers: ApiConstants.headers,
        body: {
          "invoice_id": invoiceId.toString(),
          "user_id": user?.id.toString() ?? "0",
        },
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi khi xóa: $e"};
    }
  }

  // 6. Tạo hóa đơn V2 (Tự động tính dựa trên chỉ số điện nước)
  static Future<Map<String, dynamic>> createInvoiceWithMeter({
    required dynamic roomId,
    required int month,
    required int year,
    required String newElec,
    required String newWater,
    required bool isMeterChecked,
    bool isProRata = false,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final body = {
        "room_id": roomId.toString(),
        "billing_month": month.toString(),
        "billing_year": year.toString(),
        "new_elec": newElec,
        "new_water": newWater,
        "is_meter_checked": isMeterChecked ? "1" : "0",
        "is_pro_rata": isProRata ? "1" : "0",
        "user_id": (await AuthService.getCurrentUser())?.id.toString() ?? "0",
      };

      if (isProRata && startDate != null && endDate != null) {
        body["start_date"] = startDate;
        body["end_date"] = endDate;
      }

      final response = await http.post(
        Uri.parse("${ApiConstants.invoices}/create_invoice.php"),
        headers: ApiConstants.headers,
        body: body,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi tạo hóa đơn"};
    }
  }

  // 7. Lấy danh sách nhà có phòng cần lập hóa đơn
  static Future<List<HouseModel>> getHousesForInvoicing(
    int month,
    int year,
  ) async {
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

      final url =
          "${ApiConstants.invoices}/get_invoices.php?action=houses_ready"
          "&month=$month&year=$year&user_id=$userId&role=$role&managed_house_id=$mHouseId";

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List)
              .map((json) => HouseModel.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Lỗi getHousesForInvoicing: $e");
    }
    return [];
  }

  // 8. Kiểm tra trạng thái hóa đơn (Polling)
  static Future<Map<String, dynamic>> checkInvoiceStatus(
    dynamic invoiceId,
  ) async {
    try {
      final user = await AuthService.getCurrentUser();
      final userId = user?.id ?? 0;
      final role = user?.role ?? 'landlord';
      final mHouseId = user?.managedHouseId ?? 0;
      final response = await http.get(
        Uri.parse(
          "${ApiConstants.invoices}/get_invoices.php?action=status_check&id=$invoiceId&user_id=$userId&role=$role&managed_house_id=$mHouseId",
        ),
        headers: ApiConstants.headers,
      );
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  // 9. Lấy chi tiết một hóa đơn
  static Future<InvoiceModel?> getInvoiceDetail(dynamic invoiceId) async {
    try {
      final user = await AuthService.getCurrentUser();
      final userId = user?.id ?? 0;
      final role = user?.role ?? 'landlord';
      final mHouseId = user?.managedHouseId ?? 0;
      final response = await http.get(
        Uri.parse(
          "${ApiConstants.invoices}/get_invoices.php?id=$invoiceId&user_id=$userId&role=$role&managed_house_id=$mHouseId",
        ),
        headers: ApiConstants.headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return InvoiceModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint("Lỗi getInvoiceDetail: $e");
      return null;
    }
  }
}
