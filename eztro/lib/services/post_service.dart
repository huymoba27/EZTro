import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/api_constants.dart';
import '../models/post_model.dart';
import 'auth_service.dart';

class PostService {
  static String get baseUrl => ApiConstants.baseUrl;

  // Lấy danh sách tin đăng
  static Future<List<PostModel>> getPosts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts/get_posts.php'));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List).map((item) => PostModel.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi getPosts: $e");
      return [];
    }
  }

  // Lấy danh sách phòng trống để đăng tin (Thông minh hóa phân quyền)
  static Future<List<Map<String, dynamic>>> getAvailableRooms() async {
    try {
      final user = await AuthService.getCurrentUser();
      final userId = user?.id ?? 0;
      final role = user?.role ?? 'landlord';
      final mHouseId = user?.managedHouseId ?? 0;

      final url = '$baseUrl/rooms/get_rooms.php?status=empty&user_id=$userId&role=$role&managed_house_id=$mHouseId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi getAvailableRooms: $e");
      return [];
    }
  }

  // Tạo tin đăng mới
  static Future<Map<String, dynamic>> createPost(PostModel post) async {
    try {
      final body = post.toMap();
      body['action'] = 'save';
      final response = await http.post(
        Uri.parse('$baseUrl/posts/save_post.php'),
        body: body,
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  // Lấy chi tiết một bài đăng
  static Future<PostModel?> getPostDetail(int id, {int? userId}) async {
    try {
      String url = '$baseUrl/posts/get_posts.php?id=$id';
      if (userId != null) {
        url += '&user_id=$userId';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = json.decode(utf8.decode(response.bodyBytes));
        if (result['status'] == 'success') {
          return PostModel.fromJson(result['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint("Lỗi getPostDetail: $e");
      return null;
    }
  }

  static Future<List<PostModel>> getOwnerPosts(int userId) async {
    try {
      final user = await AuthService.getCurrentUser();
      final role = user?.role ?? 'landlord';
      final mHouseId = user?.managedHouseId ?? 0;

      final url = '$baseUrl/posts/get_posts.php?user_id=$userId&role=$role&managed_house_id=$mHouseId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List).map((p) => PostModel.fromJson(p)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching owner posts: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>> closePost(int postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/save_post.php'),
        body: {'action': 'close', 'id': postId.toString()},
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/save_post.php'),
        body: {'action': 'delete', 'id': postId.toString()},
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createRentalRequest({
    required int postId,
    required String customerName,
    required String customerPhone,
    String? message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/create_rental_request.php'),
        body: {
          'post_id': postId.toString(),
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'message': message ?? '',
        },
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<List<Map<String, dynamic>>> getRentalRequests(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts/get_rental_requests.php?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching rental requests: $e");
    }
    return [];
  }
}
