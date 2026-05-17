import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/post_model.dart';
import '../../../services/favorite_service.dart';
import '../../../services/auth_service.dart';

final favoriteProvider = StateNotifierProvider.autoDispose<FavoriteNotifier, AsyncValue<List<PostModel>>>((ref) {
  return FavoriteNotifier();
});

class FavoriteNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  FavoriteNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final favorites = await FavoriteService.getFavorites(user.id);
      state = AsyncValue.data(favorites);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> toggleFavorite(int postId) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return false;

    try {
      final res = await FavoriteService.toggleFavorite(userId: user.id, postId: postId);
      if (res['status'] == 'success') {
        refresh(); // Refresh list after toggle
        return true;
      }
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
    }
    return false;
  }
}
