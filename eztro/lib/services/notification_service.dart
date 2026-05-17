import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import '../models/notification_model.dart';

class NotificationService {
  /// Lấy danh sách thông báo theo user
  static Future<List<NotificationModel>> getNotifications({
    required int userId,
    String filter = 'all',
  }) async {
    try {
      final url = "${ApiConstants.baseUrl}/notifications/get_notifications.php?user_id=$userId&filter=$filter";
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List).map((item) => NotificationModel.fromJson(item)).toList();
        }
      }
    } catch (e) { debugPrint("Error getNotifications: $e"); }
    return [];
  }

  /// Đánh dấu đã đọc một thông báo
  static Future<bool> markAsRead({required int userId, required int notificationId}) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/notifications/update_notifications.php"),
        headers: ApiConstants.headers,
        body: {"action": "read", "user_id": userId.toString(), "notification_id": notificationId.toString()},
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  /// Lấy số lượng thông báo chưa đọc
  static Future<int> getUnreadCount(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/notifications/get_notifications.php?action=unread_count&user_id=$userId"),
        headers: ApiConstants.headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['unread'] ?? 0;
      }
    } catch (e) { debugPrint("Error getUnreadCount: $e"); }
    return 0;
  }

  /// Đánh dấu tất cả đã đọc
  static Future<bool> markAllRead({required int userId}) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/notifications/update_notifications.php"),
        headers: ApiConstants.headers,
        body: {"action": "read_all", "user_id": userId.toString()},
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['status'] == 'success';
      }
    } catch (e) { debugPrint("Error markAllRead: $e"); }
    return false;
  }

  /// Gửi thông báo mới
  static Future<bool> pushNotification({
    required int userId,
    required String title,
    required String description,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/notifications/save_notification.php"),
        headers: {
          ...ApiConstants.headers,
          "Content-Type": "application/json",
        },
        body: json.encode({
          'user_id': userId,
          'title': title,
          'description': description,
          'type': type,
          'metadata': metadata ?? {},
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['status'] == 'success';
      }
    } catch (e) {
      debugPrint("Error pushNotification: $e");
    }
    return false;
  }
}
