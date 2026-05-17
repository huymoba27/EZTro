import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service lưu trữ lịch sử chat AI vào bộ nhớ cục bộ.
/// Hỗ trợ tách riêng lịch sử cho chủ trọ (landlord) và khách thuê (tenant).
class ChatStorageService {
  static const String _landlordMessagesKey = 'ai_chat_messages_landlord';
  static const String _landlordHistoryKey = 'ai_chat_history_landlord';
  static const String _tenantMessagesKey = 'ai_chat_messages_tenant';
  static const String _tenantHistoryKey = 'ai_chat_history_tenant';
  static const int _maxMessages = 100;

  // ============================================================
  // LANDLORD CHAT (Chủ trọ / Quản lý)
  // ============================================================

  /// Lưu tin nhắn hiển thị của chủ trọ
  static Future<void> saveMessages(List<Map<String, dynamic>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesToSave = messages.length > _maxMessages
        ? messages.sublist(messages.length - _maxMessages)
        : messages;
    await prefs.setString(_landlordMessagesKey, jsonEncode(messagesToSave));
  }

  /// Tải tin nhắn đã lưu của chủ trọ
  static Future<List<Map<String, dynamic>>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_landlordMessagesKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Lưu lịch sử API của chủ trọ
  static Future<void> saveHistory(List<dynamic> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyToSave =
        history.length > 20 ? history.sublist(history.length - 20) : history;
    await prefs.setString(_landlordHistoryKey, jsonEncode(historyToSave));
  }

  /// Tải lịch sử API của chủ trọ
  static Future<List<dynamic>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_landlordHistoryKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return jsonDecode(jsonStr) as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  /// Xóa lịch sử chat chủ trọ
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_landlordMessagesKey);
    await prefs.remove(_landlordHistoryKey);
  }

  // ============================================================
  // TENANT CHAT (Khách thuê / Khách vãng lai)
  // ============================================================

  /// Lưu tin nhắn hiển thị của khách thuê
  static Future<void> saveTenantMessages(
      List<Map<String, dynamic>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesToSave = messages.length > _maxMessages
        ? messages.sublist(messages.length - _maxMessages)
        : messages;
    await prefs.setString(_tenantMessagesKey, jsonEncode(messagesToSave));
  }

  /// Tải tin nhắn đã lưu của khách thuê
  static Future<List<Map<String, dynamic>>> loadTenantMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_tenantMessagesKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Lưu lịch sử API của khách thuê
  static Future<void> saveTenantHistory(List<dynamic> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyToSave =
        history.length > 20 ? history.sublist(history.length - 20) : history;
    await prefs.setString(_tenantHistoryKey, jsonEncode(historyToSave));
  }

  /// Tải lịch sử API của khách thuê
  static Future<List<dynamic>> loadTenantHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_tenantHistoryKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return jsonDecode(jsonStr) as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  /// Xóa lịch sử chat khách thuê
  static Future<void> clearTenantAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tenantMessagesKey);
    await prefs.remove(_tenantHistoryKey);
  }
}
