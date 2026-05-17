import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:eztro/core/widgets/widgets.dart';

class RentalRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onCall;
  final VoidCallback onContacted;

  const RentalRequestCard({
    super.key,
    required this.request,
    required this.onCall,
    required this.onContacted,
  });

  @override
  Widget build(BuildContext context) {
    final String customerName = request['customer_name'] ?? "Khách hàng";
    final String firstLetter = customerName.isNotEmpty ? customerName[0].toUpperCase() : "?";

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng đang phát triển'), duration: Duration(seconds: 1))), // Future: Request details
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🎯 PREMIUM: Avatar tròn 48x48 với chữ cái đầu
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        firstLetter,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Thông tin khách hàng
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        CardInfoRow(
                          icon: Icons.phone_android_outlined,
                          text: request['customer_phone'] ?? "N/A",
                          textColor: AppColors.primary,
                        ),
                        const SizedBox(height: 6),
                        CardInfoRow(
                          icon: Icons.access_time_outlined,
                          text: "Yêu cầu lúc: ${request['created_at'].toString().split(' ')[0]}",
                        ),
                      ],
                    ),
                  ),
                  // Nút gọi điện nhanh
                  IconButton(
                    onPressed: onCall,
                    icon: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(Icons.phone, color: Colors.green, size: 16),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
          const SizedBox(height: 12),
          // Box thông tin bài đăng quan tâm
          Container(
            margin: const EdgeInsets.only(left: 64),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "QUAN TÂM BÀI ĐĂNG:",
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  request['post_title'] ?? "N/A",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "Phòng: ${request['room_name']} • ${request['house_name']}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (request['message'] != null && request['message'].toString().isNotEmpty) ...[
                  const Divider(height: 16),
                  Text(
                    "\"${request['message']}\"",
                    style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Nút hành động phụ
          Padding(
            padding: const EdgeInsets.only(left: 64),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: onContacted,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text("ĐÃ LIÊN HỆ"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}
