import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'auth_service.dart';
import '../models/statistics_model.dart';

class StatisticsService {
  static Future<StatisticsModel> getStatsSummary({
    int houseId = 0,
    int? year,
  }) async {
    try {
      int finalId = 0;
      String role = 'landlord';
      int mHouseId = 0;

      final user = await AuthService.getCurrentUser();
      if (user != null) {
        finalId = user.id;
        role = user.role;
        mHouseId = user.managedHouseId ?? 0;
      }

      final selectedYear = year ?? DateTime.now().year;
      String url =
          "${ApiConstants.reports}/get_stats_summary.php?house_id=$houseId&year=$selectedYear&user_id=$finalId&role=$role&managed_house_id=$mHouseId";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final data = json.decode(body);
        return StatisticsModel.fromJson(data);
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    }
    
    // Return empty model instead of raw map on error
    return StatisticsModel(
      summary: StatsSummary(
        totalHouses: 0,
        totalRooms: 0,
        occupiedRooms: 0,
        totalRevenue: 0,
        totalExpense: 0,
        netProfit: 0,
      ),
      revenueChart: List.filled(12, 0.0),
      expenseChart: List.filled(12, 0.0),
    );
  }
}
