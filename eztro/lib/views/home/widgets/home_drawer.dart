import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../auth/list/manager_staff_list_screen.dart';
import '../../post/list/post_management_screen.dart';

class HomeDrawer extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onLogout;

  const HomeDrawer({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1541746972996-4e0b0f43e01a?q=80&w=1000&auto=format&fit=crop',
                ),
                fit: BoxFit.cover,
                opacity: 0.2,
              ),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 40),
            ),
            accountName: Text(
              user?.fullName ?? "Người dùng",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              user?.username ?? "username@eztro",
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.person_outline_rounded,
            title: "Thông tin cá nhân",
            onTap: () {
              Navigator.pop(context);
              // TODO: Profile Screen
            },
          ),
          _buildDrawerItem(
            icon: Icons.campaign_outlined,
            title: "Đăng tin cho thuê",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PostManagementScreen(),
                ),
              );
            },
          ),
          if (user?.role == 'landlord' || user?.role == 'admin')
            _buildDrawerItem(
              icon: Icons.supervisor_account_rounded,
              title: "Quản lý nhân viên",
              color: Colors.teal,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManagerStaffListScreen(),
                  ),
                );
              },
            ),
          _buildDrawerItem(
            icon: Icons.shield_outlined,
            title: "Chính sách bảo mật",
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng đang phát triển'), duration: Duration(seconds: 1))),
          ),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            title: "Cài đặt hệ thống",
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng đang phát triển'), duration: Duration(seconds: 1))),
          ),
          const Spacer(),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout_rounded,
            title: "Đăng xuất",
            color: Colors.red,
            onTap: onLogout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = AppColors.primary,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color == Colors.red ? Colors.red : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }
}
