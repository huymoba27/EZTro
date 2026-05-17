import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_helper.dart';
import '../../../providers/notification_provider.dart';

class HomeHeader extends ConsumerWidget {
  final UserModel? user;
  final VoidCallback onNotificationTap;

  const HomeHeader({
    super.key,
    required this.user,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Container(
      padding: EdgeInsets.fromLTRB(10, statusBarHeight + 12, 16, 12),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // Biểu tượng chú chim (Bấm vào để mở Drawer)
                SizedBox(
                  width: 70,
                  height: 70,
                  child: Lottie.asset(
                    "assets/lottie/welcome_bird.json",
                    repeat: true,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hàng 1: Xin chào + Tên người dùng (Viết Hoa)
                      Row(
                        children: [
                          const Text(
                            "Xin chào, ",
                            style: TextStyle(
                              color: Colors.white70, // Làm sáng chữ Xin chào
                              fontSize: 14,
                              fontWeight: FontWeight.w400, // Tăng độ đậm nhẹ
                            ),
                          ),
                          Flexible(
                            child: Text(
                              StringHelper.capitalizeEachWord(
                                user?.fullName ?? "Người dùng",
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Hàng 2: Vai trò (Role)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getRoleDisplayName(user?.role),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Nút chuông thông báo
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(40),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    size: 26,
                    color: Colors.white,
                  ),
                  onPressed: onNotificationTap,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 9 ? "9+" : "$unreadCount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String? role) {
    switch (role?.toLowerCase()) {
      case 'landlord':
        return "LANDLORD";
      case 'manager':
        return "MANAGER";
      case 'admin':
        return "ADMIN";
      case 'tenant':
        return "TENANT";
      default:
        return "USER";
    }
  }
}
