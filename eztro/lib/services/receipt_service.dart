import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'auth_service.dart';
import '../models/receipt_model.dart';

class ReceiptService {
  static Future<List<ReceiptModel>> getReceipts({int? houseId, int? month, int? year}) async {
    try {
      int finalId = houseId ?? 0;
      int userId = 0;
      String role = 'landlord';
      int mHouseId = 0;

      final user = await AuthService.getCurrentUser();
      if (user != null) {
        userId = user.id;
        role = user.role;
        mHouseId = user.managedHouseId ?? 0;
      }

      String url = "${ApiConstants.baseUrl}/receipts/get_receipts.php?house_id=$finalId&user_id=$userId&role=$role&managed_house_id=$mHouseId";
      if (month != null) url += "&month=$month";
      if (year != null) url += "&year=$year";
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List).map((json) => ReceiptModel.fromJson(json)).toList();
        }
      }
    } catch (e) { debugPrint("Error fetching receipts: $e"); }
    return [];
  }

  static Future<Map<String, dynamic>> createReceipt({
    required int houseId,
    int? roomId,
    int? invoiceId,
    required String tenantName,
    required double amount,
    required String receiptDate,
    String paymentMethod = 'Tiền mặt',
    String receiptType = 'monthly_bill',
    String description = '',
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/receipts/save_receipt.php"),
        body: {
          "action": "save",
          "user_id": (user?.id ?? 0).toString(),
          "house_id": houseId.toString(),
          "room_id": roomId?.toString() ?? "",
          "invoice_id": invoiceId?.toString() ?? "",
          "tenant_name": tenantName,
          "amount": amount.toString(),
          "receipt_date": receiptDate,
          "payment_method": paymentMethod,
          "receipt_type": receiptType,
          "description": description,
        },
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getReceiptDetail(int id) async {
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

      final response = await http.get(Uri.parse(
          "${ApiConstants.baseUrl}/receipts/get_receipts.php?id=$id&user_id=$userId&role=$role&managed_house_id=$mHouseId"));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['data'] is Map) {
          return data['data'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching receipt detail: $e");
    }
    return {};
  }
}
