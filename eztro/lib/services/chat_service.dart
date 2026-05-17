import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import '../models/chat_model.dart';

class ChatService {
  static String get baseUrl => "${ApiConstants.baseUrl}/posts";

  static Future<List<ChatModel>> getChatList(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_chats.php?user_id=$userId"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success' && data['data'] != null) {
          return (data['data'] as List)
              .map((json) => ChatModel.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Error getChatList: $e");
    }
    return [];
  }

  static Future<List<ChatMessageModel>> getChatHistory(
    int user1,
    int user2,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/get_chats.php?action=history&user_id=$user1&other_id=$user2",
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success' && data['data'] != null) {
          return (data['data'] as List)
              .map((json) => ChatMessageModel.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Error getChatHistory: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int senderId,
    required int receiverId,
    int? postId,
    required String content,
    String? imagePath,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/send_message.php"));
      
      request.fields['sender_id'] = senderId.toString();
      request.fields['receiver_id'] = receiverId.toString();
      request.fields['post_id'] = postId?.toString() ?? '';
      request.fields['content'] = content;

      if (imagePath != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<void> markAsRead(int senderId, int receiverId) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/mark_as_read.php"),
        body: {
          'sender_id': senderId.toString(),
          'receiver_id': receiverId.toString(),
        },
      );
    } catch (e) {
      debugPrint("Error markAsRead: $e");
    }
  }
}
