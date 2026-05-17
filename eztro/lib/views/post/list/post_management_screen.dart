import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/post_service.dart';
import '../../../core/constants/app_colors.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../house/list/widgets/house_list_skeleton.dart';
import '../widgets/post_management_card.dart';
import '../create/create_post_screen.dart';
import '../providers/post_notifier.dart';
import '../../../core/utils/dialog_helper.dart';

class PostManagementScreen extends ConsumerStatefulWidget {
  const PostManagementScreen({super.key});

  @override
  ConsumerState<PostManagementScreen> createState() =>
      _PostManagementScreenState();
}

class _PostManagementScreenState extends ConsumerState<PostManagementScreen> {
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  Future<void> _deletePost(int postId) async {
    DialogHelper.showConfirmDialog(
      context: context,
      title: "XÁC NHẬN XÓA",
      message: "Bạn có chắc muốn xóa vĩnh viễn tin đăng này?",
      onConfirm: () async {
        setState(() => isLoading = true);
        final result = await PostService.deletePost(postId);
        if (mounted) {
          setState(() => isLoading = false);
          if (result['status'] == 'success') {
            DialogHelper.showSuccess(context, "Đã xóa tin thành công!");
            ref.read(postNotifierProvider.notifier).refresh();
          } else {
            DialogHelper.showError(
              context,
              result['message'] ?? "Lỗi không xác định",
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedPosts = ref.watch(filteredOwnerPostsProvider);
    final postsAsync = ref.watch(postNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "QUẢN LÝ TIN ĐĂNG",
        onBack: () => Navigator.pop(context),
        isSearching: isSearching,
        onSearchToggle: () => setState(() => isSearching = !isSearching),
        onSearchChanged: (q) =>
            ref.read(postFilterProvider.notifier).setQuery(q),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
          if (result == true) {
            ref.read(postNotifierProvider.notifier).refresh();
          }
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: postsAsync.when(
              data: (_) {
                if (displayedPosts.isEmpty) {
                  return _buildEmptyState();
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.read(postNotifierProvider.notifier).refresh(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: displayedPosts.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 10,
                      thickness: 10,
                      color: Color(0xFFF2F2F7),
                    ),
                    itemBuilder: (context, index) {
                      final post = displayedPosts[index];
                      return PostManagementCard(
                        post: post,
                        onDelete: () => _deletePost(post.id ?? 0),
                      );
                    },
                  ),
                );
              },
              loading: () => const HouseListSkeleton(),
              error: (err, stack) => Center(child: Text("Lỗi: $err")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return DialogHelper.buildEmptyState(
      icon: Icons.campaign_outlined,
      title: "Bạn chưa có tin đăng nào",
      subtitle: "Dữ liệu tin đăng sẽ hiển thị tại đây",
    );
  }
}
