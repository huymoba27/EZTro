import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'auth_service.dart';

class ExpenseService {
  static Future<List<Map<String, dynamic>>> getExpenses({
    int? houseId,
    int? month,
    int? year,
  }) async {
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

      String url =
          "${ApiConstants.baseUrl}/expenses/get_expenses.php?house_id=$finalId&user_id=$userId&role=$role&managed_house_id=$mHouseId";
      if (month != null) url += "&month=$month";
      if (year != null) url += "&year=$year";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching expenses: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>> createExpense({
    required int houseId,
    int? roomId,
    required String receiverName,
    required double amount,
    required String expenseDate,
    String paymentMethod = 'Tiền mặt',
    String expenseType = 'other',
    String description = '',
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/expenses/save_expense.php"),
        body: {
          "action": "save",
          "user_id": (user?.id ?? 0).toString(),
          "house_id": houseId.toString(),
          "room_id": roomId?.toString() ?? "",
          "receiver_name": receiverName,
          "amount": amount.toString(),
          "expense_date": expenseDate,
          "payment_method": paymentMethod,
          "expense_type": expenseType,
          "description": description,
        },
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getExpenseDetail(int id) async {
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

      final response = await http.get(
        Uri.parse(
          "${ApiConstants.baseUrl}/expenses/get_expenses.php?id=$id&user_id=$userId&role=$role&managed_house_id=$mHouseId",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['data'] is Map) {
          return data['data'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching expense detail: $e");
    }
    return {};
  }
}
