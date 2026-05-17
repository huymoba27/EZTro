import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import '../models/post_model.dart';

class FavoriteService {
  static Future<Map<String, dynamic>> toggleFavorite({
    required int userId,
    required int postId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.serverUrl}/backend_api/favorites/toggle_favorite.php"),
        body: {
          'user_id': userId.toString(),
          'post_id': postId.toString(),
        },
        headers: ApiConstants.headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {"status": "error", "message": "Lỗi server (${response.statusCode})"};
    } catch (e) {
      return {"status": "error", "message": "Lỗi kết nối: $e"};
    }
  }

  static Future<List<PostModel>> getFavorites(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.serverUrl}/backend_api/favorites/get_favorites.php?user_id=$userId"),
        headers: ApiConstants.headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return (data['data'] as List)
              .map((item) => PostModel.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
