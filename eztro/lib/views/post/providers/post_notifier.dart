import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/post_model.dart';
import '../../../services/post_service.dart';
import '../../../services/auth_service.dart';

class PostNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  PostNotifier() : super(const AsyncValue.loading());

  Future<void> loadOwnerPosts() async {
    state = const AsyncValue.loading();
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        final posts = await PostService.getOwnerPosts(user.id);
        state = AsyncValue.data(posts);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        final posts = await PostService.getOwnerPosts(user.id);
        state = AsyncValue.data(posts);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final postNotifierProvider =
    StateNotifierProvider<PostNotifier, AsyncValue<List<PostModel>>>((ref) {
      final notifier = PostNotifier();
      notifier.loadOwnerPosts();
      return notifier;
    });

// --- Filter Logic ---
class PostFilter {
  final int? houseId;
  final double? minPrice;
  final double? maxPrice;
  final String query;

  PostFilter({
    this.houseId,
    this.minPrice,
    this.maxPrice,
    this.query = "",
  });

  PostFilter copyWith({
    int? houseId,
    double? minPrice,
    double? maxPrice,
    String? query,
    bool clearHouse = false,
    bool clearPrice = false,
  }) {
    return PostFilter(
      houseId: clearHouse ? null : (houseId ?? this.houseId),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      query: query ?? this.query,
    );
  }
}

class PostFilterNotifier extends StateNotifier<PostFilter> {
  PostFilterNotifier() : super(PostFilter());

  void setHouse(int? houseId) => state = state.copyWith(houseId: houseId, clearHouse: houseId == null);
  void setPriceRange(double? min, double? max) => state = state.copyWith(minPrice: min, maxPrice: max, clearPrice: min == null && max == null);
  void setQuery(String q) => state = state.copyWith(query: q);
  void clear() => state = PostFilter();
}

final postFilterProvider = StateNotifierProvider<PostFilterNotifier, PostFilter>((ref) => PostFilterNotifier());

final filteredOwnerPostsProvider = Provider<List<PostModel>>((ref) {
  final postsAsync = ref.watch(postNotifierProvider);
  final filter = ref.watch(postFilterProvider);
  final query = filter.query.toLowerCase();

  return postsAsync.when(
    data: (posts) {
      return posts.where((p) {
        // Lọc theo search
        final matchesSearch = p.title.toLowerCase().contains(query) ||
            (p.houseName?.toLowerCase().contains(query) ?? false);
        if (!matchesSearch) return false;

        // Lọc theo nhà
        if (filter.houseId != null && p.houseId != filter.houseId) return false;

        // Lọc theo giá
        double? price;
        try {
          String rawPrice = (p.originalPrice ?? p.priceDisplay ?? "0").replaceAll(RegExp(r'[^0-9.]'), '');
          price = double.tryParse(rawPrice);
        } catch (_) {}

        if (price != null) {
          if (filter.minPrice != null && price < filter.minPrice!) return false;
          if (filter.maxPrice != null && price > filter.maxPrice!) return false;
        }

        return true;
      }).toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});
