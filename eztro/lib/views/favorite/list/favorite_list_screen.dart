import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../home/post_detail_screen.dart';
import '../../search/widgets/post_list_card.dart';
import '../providers/favorite_notifier.dart';

class FavoriteListScreen extends ConsumerStatefulWidget {
  const FavoriteListScreen({super.key});

  @override
  ConsumerState<FavoriteListScreen> createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends ConsumerState<FavoriteListScreen> {
  @override
  Widget build(BuildContext context) {
    final favoriteAsync = ref.watch(favoriteProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "PHÒNG ĐÃ LƯU",
        onBack: () => Navigator.pop(context),
      ),
      body: favoriteAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(child: Text("Lỗi: $err")),
        data: (posts) {
          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(favoriteProvider.notifier).refresh(),
            color: AppColors.primary,
            child: posts.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: const EmptyStateWidget(
                        icon: Icons.bookmark_border_rounded,
                        title: "Bạn chưa lưu phòng nào",
                        subtitle: "Các phòng bạn yêu thích sẽ hiển thị tại đây",
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: posts.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.8,
                      indent: 12,
                      endIndent: 12,
                      color: Colors.black.withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return PostListCard(
                        post: post,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PostDetailScreen(postId: post.id!),
                            ),
                          );
                          // Refresh when coming back in case they unfavorited in detail screen
                          ref.read(favoriteProvider.notifier).refresh();
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
