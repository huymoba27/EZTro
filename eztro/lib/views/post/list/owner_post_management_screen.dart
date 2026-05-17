import 'package:flutter/material.dart';
import '../../../models/post_model.dart';
import '../../../services/post_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_constants.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../core/utils/dialog_helper.dart';

class OwnerPostManagementScreen extends StatefulWidget {
  const OwnerPostManagementScreen({super.key});

  @override
  State<OwnerPostManagementScreen> createState() =>
      _OwnerPostManagementScreenState();
}

class _OwnerPostManagementScreenState extends State<OwnerPostManagementScreen> {
  late Future<List<PostModel>> _postsFuture;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _refreshPosts();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = _loadPosts();
    });
  }

  Future<List<PostModel>> _loadPosts() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      return PostService.getOwnerPosts(user.id);
    }
    return [];
  }

  Future<void> _closePost(int postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc muốn đóng/ẩn tin đăng này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Đồng ý", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await PostService.closePost(postId);
      if (mounted) {
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Đã ẩn tin đăng!")));
          _refreshPosts();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Lỗi: ${result['message']}")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () => Navigator.pop(context), // Mở drawer hoặc quay lại
        ),
        title: const Text(
          "Bài đăng cho thuê",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: Center(
              child: InkWell(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng đang phát triển'), duration: Duration(seconds: 1))),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            color: Colors.white,
            child: Column(
              children: [
                AppFilterBar(
                  selectedPillValue: _selectedStatus,
                  onPillSelected: (v) => setState(() => _selectedStatus = v),
                  pillItems: [
                    FilterPillItem(
                      label: "Tất cả",
                      icon: Icons.format_list_bulleted,
                      color: Colors.blue,
                      value: "all",
                    ),
                    FilterPillItem(
                      label: "Đang hiển thị",
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      value: "active",
                    ),
                    FilterPillItem(
                      label: "Đã ẩn",
                      icon: Icons.visibility_off_outlined,
                      color: Colors.grey,
                      value: "hidden",
                    ),
                    FilterPillItem(
                      label: "Hết phòng",
                      icon: Icons.do_not_disturb_alt,
                      color: Colors.red,
                      value: "full",
                    ),
                  ],
                  dropdownItems: [
                    DropdownFilterItem(
                      icon: Icons.business,
                      label: "Tất cả khu / dãy",
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng đang phát triển'), duration: Duration(seconds: 1))),
                    ),
                    DropdownFilterItem(
                      icon: Icons.local_offer_outlined,
                      label: "Tất cả mức giá",
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng đang phát triển'), duration: Duration(seconds: 1))),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // List Section
          Expanded(
            child: FutureBuilder<List<PostModel>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                List<PostModel> posts = snapshot.data ?? [];

                // Lọc theo trạng thái (Giả lập vì chưa nối API)
                if (_selectedStatus != 'all') {
                  // Chú ý: Ở đây ta ví dụ, thực tế cần check status thật từ API
                }

                if (posts.isEmpty) {
                  return DialogHelper.buildEmptyState(
                    icon: Icons.campaign_outlined,
                    title: "Chưa có bài đăng nào",
                    subtitle: "Các bài đăng cho thuê sẽ hiển thị tại đây",
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: posts.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 10,
                    thickness: 10,
                    color: Color(0xFFF2F2F7),
                  ),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildFlatPostCard(post);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatPostCard(PostModel post) {
    // MOCK DATA để giống thiết kế
    int photoCount = post.images != null ? (post.images!.split(',').length) : 0;
    if (photoCount == 0) photoCount = 6; // Mock

    String capacity = "Sức chứa: 2 người";
    String furniture = "Nội thất: Cơ bản";
    if (post.amenities != null && post.amenities!.length > 3) {
      furniture = "Nội thất: Full nội thất";
    }

    int views = 120;
    int contacts = 8;

    String statusLabel = "Đang hiển thị";
    Color statusColor = Colors.green;
    if (post.status == 'hidden') {
      statusLabel = "Đã ẩn";
      statusColor = Colors.grey;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bên trái: Ảnh lớn
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 140,
                  color: Colors.grey[200],
                  child: post.images != null && post.images!.isNotEmpty
                      ? Image.network(
                          "${ApiConstants.baseUrl}/uploads/rooms/${post.images}",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image, color: Colors.grey),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$photoCount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Bên phải: Thông tin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng 1: Tiêu đề + Badge + 3 chấm
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        post.roomName != null
                            ? "Phòng ${post.roomName}"
                            : post.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.black54,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Hàng 2: Giá
                Text(
                  "${post.priceDisplay ?? 'Chưa có giá'} / tháng",
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                // Hàng 3: Vị trí
                _buildInfoRow(
                  Icons.location_on_outlined,
                  "${post.ward ?? 'Ninh Kiều'}, ${post.city ?? 'Cần Thơ'}",
                ),
                // Hàng 4: Sức chứa
                _buildInfoRow(Icons.person_outline, capacity),
                // Hàng 5: Nội thất
                _buildInfoRow(Icons.weekend_outlined, furniture),
                // Hàng 6: Lượt xem / Liên hệ
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        size: 12,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$views lượt xem",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          "|",
                          style: TextStyle(fontSize: 11, color: Colors.black26),
                        ),
                      ),
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 12,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$contacts liên hệ",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                // Hàng 7: Các nút
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Colors.blue,
                        ),
                        label: const Text(
                          "Chỉnh sửa",
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: BorderSide(color: Colors.blue.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _closePost(post.id ?? 0),
                        icon: Icon(
                          post.status == 'hidden'
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_off_outlined,
                          size: 14,
                          color: Colors.red,
                        ),
                        label: Text(
                          post.status == 'hidden' ? "Hiển thị bài" : "Ẩn bài",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: BorderSide(color: Colors.red.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: Colors.black54),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
