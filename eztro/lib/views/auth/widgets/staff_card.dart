import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class StaffCard extends StatelessWidget {
  final Map<String, dynamic> staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StaffCard({
    super.key,
    required this.staff,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String fullName = staff['full_name'] ?? "Nhân viên";
    final String firstLetter = fullName.isNotEmpty ? fullName[0].toUpperCase() : "NV";
    final String phone = staff['phone'] ?? "Không có số";
    final String houseName = staff['house_name'] ?? "Chưa gán";

    return Column(
      children: [
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng đang phát triển'), duration: Duration(seconds: 1))), // Removed edit logic
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar Circle
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withAlpha(51),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        firstLetter,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                fullName.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFF263238),
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildRoleBadge("NHÂN VIÊN"),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone_android_outlined,
                                size: 14, color: Colors.black38),
                            const SizedBox(width: 6),
                            Text(
                              phone,
                              style: const TextStyle(
                                color: Colors.black, // Đã đổi sang màu đen
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.home_outlined,
                                size: 14, color: Colors.black38),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                houseName,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.teal.shade700.withAlpha(26),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.teal.shade700,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
