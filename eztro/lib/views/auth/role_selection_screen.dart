import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../home/home_screen.dart';
import '../home/tenant_home_screen.dart';
import 'providers/auth_provider.dart';

class RoleSelectionScreen extends ConsumerWidget {
  final int? userId;
  const RoleSelectionScreen({super.key, this.userId});

  Future<void> _updateRole(
    BuildContext context,
    WidgetRef ref,
    String role,
  ) async {
    final success = await ref.read(authProvider.notifier).updateRole(role);
    if (success) {
      if (!context.mounted) return;

      Widget destination;
      if (role != 'tenant') {
        destination = const HomeScreen();
      } else {
        destination = const TenantHomeScreen();
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => destination),
        (route) => false,
      );
    } else {
      if (!context.mounted) return;
      DialogHelper.showError(
        context,
        "Không thể cập nhật vai trò. Vui lòng thử lại.",
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Bạn là ai?",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Chọn vai trò của bạn để EZTro tối ưu hóa trải nghiệm phù hợp nhất",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 60),
                    _buildRoleCard(
                      context,
                      title: "CHỦ TRỌ",
                      sub: "Tôi sở hữu và quản lý các dãy trọ",
                      icon: Icons.admin_panel_settings_rounded,
                      color: AppColors.primary,
                      onTap: () => _updateRole(context, ref, 'landlord'),
                    ),
                    const SizedBox(height: 20),
                    _buildRoleCard(
                      context,
                      title: "KHÁCH THUÊ",
                      sub: "Tôi muốn tìm và quản lý phòng đang thuê",
                      icon: Icons.person_pin_rounded,
                      color: Colors.blue,
                      onTap: () => _updateRole(context, ref, 'tenant'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String sub,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(20),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
