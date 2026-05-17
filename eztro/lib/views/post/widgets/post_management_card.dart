import 'package:flutter/material.dart';
import '../../../models/post_model.dart';
import '../../../services/api_constants.dart';
import '../../../core/utils/format_helper.dart';
import 'package:eztro/core/widgets/widgets.dart';

class PostManagementCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onDelete;

  const PostManagementCard({
    super.key,
    required this.post,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // MOCK DATA
    int photoCount = post.images != null ? (post.images!.split(',').length) : 0;
    if (photoCount == 0) photoCount = 6;

    int views = 120;
    int contacts = 8;

    String address = "";
    if (post.ward != null && post.ward!.isNotEmpty) {
      address = post.ward!;
      if (post.city != null && post.city!.isNotEmpty) {
        address += ", ${post.city}";
      }
    } else {
      address = post.houseName ?? "Chưa rõ địa chỉ";
    }

    // Định dạng tiền tệ VNĐ
    String formattedPrice;
    try {
      String rawPrice = (post.originalPrice ?? post.priceDisplay ?? "0")
          .replaceAll(RegExp(r'[^0-9.]'), '');
      formattedPrice = CurrencyHelper.formatVND(double.parse(rawPrice));
    } catch (e) {
      formattedPrice = post.priceDisplay ?? "Chưa có giá";
    }

    const TextStyle rowStyle = TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.normal);
    const double iconSize = 14;
    const Color iconColor = Colors.black45;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ảnh bên trái (Fix cao 140)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 140,
                    color: Colors.grey[100],
                    child: post.images != null && post.images!.isNotEmpty
                        ? Image.network(
                            "${ApiConstants.baseUrl}/uploads/rooms/${post.images}",
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image, color: Colors.grey, size: 30),
                          )
                        : const Icon(Icons.image, color: Colors.grey, size: 30),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(153),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.photo_library_outlined, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text("$photoCount", 
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Thông tin bên phải
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Tiêu đề + Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          post.roomName != null ? "Phòng ${post.roomName}" : post.title,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF263238)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppStatusBadge(status: post.status == 'hidden' ? 'hidden' : 'visible'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 2. Giá tiền
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_outlined, size: iconSize, color: iconColor),
                      const SizedBox(width: 6),
                      Text(
                        "$formattedPrice / tháng",
                        style: rowStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 3. Vị trí
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: iconSize, color: iconColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: rowStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 5. Chỉ số
                  Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: iconSize, color: iconColor),
                      const SizedBox(width: 6),
                      Text("$views lượt xem", style: rowStyle),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text("•", style: TextStyle(color: Colors.black26)),
                      ),
                      const Icon(Icons.chat_bubble_outline, size: iconSize, color: iconColor),
                      const SizedBox(width: 6),
                      Text("$contacts liên hệ", style: rowStyle),
                    ],
                  ),
                  
                  const Spacer(), // Đẩy các nút xuống dưới cùng để bằng với ảnh
                  
                  // 6. Nút bấm
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text("Chỉnh sửa", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onDelete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text(
                            "Xóa bài",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
      ),
    );

  }
}

