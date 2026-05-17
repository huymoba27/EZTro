import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../post/list/post_management_screen.dart';
import '../auth/list/manager_staff_list_screen.dart';
import '../../core/constants/app_colors.dart';
import 'package:eztro/core/widgets/widgets.dart';

class LandlordMoreMenuScreen extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onLogout;

  const LandlordMoreMenuScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: const CustomAppBar(
        title: "TÙY CHỌN THÊM",
        showBackButton: false,
      ),
      body: ListView(
        children: [
          _buildUserHeader(),
          const SizedBox(height: 20),
          _buildSection("CÁ NHÂN & TÀI KHOẢN", [
            _buildMenuItem(
              icon: Icons.person_outline_rounded,
              title: "Thông tin cá nhân",
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.lock_outline_rounded,
              title: "Đổi mật khẩu",
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection("QUẢN LÝ CHO THUÊ", [
            _buildMenuItem(
              icon: Icons.campaign_outlined,
              title: "Đăng tin cho thuê",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PostManagementScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.people_outline_rounded,
              title: "Quản lý nhân viên",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManagerStaffListScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection("HỆ THỐNG", [
            _buildMenuItem(
              icon: Icons.help_outline_rounded,
              title: "Hướng dẫn sử dụng",
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.info_outline_rounded,
              title: "Về ứng dụng",
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.logout_rounded,
              title: "Đăng xuất",
              titleColor: Colors.red,
              iconColor: Colors.red,
              onTap: onLogout,
              showDivider: false,
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppColors.primary, size: 35),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? "CHỦ TRỌ",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  user?.phoneNumber ?? user?.username ?? "",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? titleColor,
    Color? iconColor,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor ?? Colors.black87),
          title: Text(
            title,
            style: TextStyle(
              color: titleColor ?? Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle != null
              ? Text(subtitle, style: const TextStyle(fontSize: 12))
              : null,
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.grey,
            size: 20,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 56,
            color: Colors.grey[200],
          ),
      ],
    );
  }
}
