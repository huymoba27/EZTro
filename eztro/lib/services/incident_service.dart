import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import '../models/incident_model.dart';
import 'auth_service.dart';

class IncidentService {
  static Future<Map<String, dynamic>> reportIncident({
    required int tenantId,
    required int roomId,
    required String title,
    required String description,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      final response = await http.post(
        Uri.parse(
          "${ApiConstants.serverUrl}/backend_api/incidents/save_incident.php",
        ),
        body: {
          'action': 'save',
          'tenant_id': tenantId.toString(),
          'user_id': (user?.id ?? 0).toString(),
          'room_id': roomId.toString(),
          'title': title,
          'description': description,
        },
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối: $e"};
    }
  }

  static Future<List<IncidentModel>> getMyIncidents({
    required int userId,
    required String role,
  }) async {
    try {
      final user = await AuthService.getCurrentUser();
      final mHouseId = user?.managedHouseId ?? 0;

      final response = await http.get(
        Uri.parse(
          "${ApiConstants.serverUrl}/backend_api/incidents/get_incidents.php?user_id=$userId&role=$role&managed_house_id=$mHouseId",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List)
              .map((item) => IncidentModel.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Lỗi getMyIncidents: $e");
    }
    return [];
  }

  static Future<List<IncidentModel>> getAllIncidents({
    required int userId,
    required String role,
  }) async {
    return getMyIncidents(
      userId: userId,
      role: role,
    ); // Dùng chung vì backend đã xử lý phân quyền
  }

  static Future<Map<String, dynamic>> updateIncidentStatus({
    required int incidentId,
    required String status,
    double? repairCost,
    int? managerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          "${ApiConstants.serverUrl}/backend_api/incidents/save_incident.php",
        ),
        body: {
          'action': 'update_status',
          'id': incidentId.toString(),
          'status': status,
          'repair_cost': repairCost?.toString() ?? '0',
          'manager_id': managerId?.toString() ?? '',
        },
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối: $e"};
    }
  }

  static Future<Map<String, dynamic>> deleteIncident(int incidentId) async {
    try {
      final response = await http.post(
        Uri.parse(
          "${ApiConstants.serverUrl}/backend_api/incidents/save_incident.php",
        ),
        body: {'action': 'delete', 'id': incidentId.toString()},
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối: $e"};
    }
  }

  static Future<IncidentModel?> getIncidentDetail(int id) async {
    try {
      final user = await AuthService.getCurrentUser();
      int userId = user?.id ?? 0;
      String role = user?.role ?? 'landlord';

      final response = await http.get(
        Uri.parse(
          "${ApiConstants.serverUrl}/backend_api/incidents/get_incidents.php?id=$id&user_id=$userId&role=$role",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return IncidentModel.fromJson(data['data']);
        }
      }
    } catch (e) {
      debugPrint("Lỗi getIncidentDetail: $e");
    }
    return null;
  }
}
