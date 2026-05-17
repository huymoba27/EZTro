import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import 'package:eztro/views/invoice/list/invoice_list_screen.dart';
import '../contract/list/contract_list_screen.dart';
import '../incident/report/incident_report_screen.dart';
import '../deposit/list/tenant_deposit_list_screen.dart';
import '../favorite/list/favorite_list_screen.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/dialog_helper.dart';

class TenantMoreMenuScreen extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onLogout;

  const TenantMoreMenuScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: const CustomAppBar(title: "TÙY CHỌN THÊM", showBackButton: false),
      body: ListView(
        children: [
          _buildUserHeader(context),
          const SizedBox(height: 20),
          _buildSection("QUẢN LÝ THUÊ TRỌ", [
            _buildMenuItem(
              icon: Icons.receipt_long_rounded,
              title: "Hóa đơn tháng",
              onTap: () =>
                  _checkLoginAndNavigate(context, const InvoiceListScreen()),
            ),
            _buildMenuItem(
              icon: Icons.description_outlined,
              title: "Hợp đồng thuê",
              onTap: () =>
                  _checkLoginAndNavigate(context, const ContractListScreen()),
            ),
            _buildMenuItem(
              icon: Icons.account_balance_wallet_outlined,
              title: "Tiền cọc phòng",
              onTap: () => _checkLoginAndNavigate(
                context,
                const TenantDepositListScreen(),
              ),
            ),
            _buildMenuItem(
              icon: Icons.report_problem_outlined,
              title: "Báo cáo sự cố",
              onTap: () =>
                  _checkLoginAndNavigate(context, const IncidentReportScreen()),
            ),
            _buildMenuItem(
              icon: Icons.favorite_border_rounded,
              title: "Phòng đã lưu",
              onTap: () =>
                  _checkLoginAndNavigate(context, const FavoriteListScreen()),
              showDivider: false,
            ),
          ]),
          const SizedBox(height: 12),
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
              showDivider: false,
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
            if (user != null)
              _buildMenuItem(
                icon: Icons.logout_rounded,
                title: "Đăng xuất",
                titleColor: Colors.red,
                iconColor: Colors.red,
                onTap: onLogout,
                showDivider: false,
              )
            else
              _buildMenuItem(
                icon: Icons.login_rounded,
                title: "Đăng nhập / Đăng ký",
                titleColor: const Color(0xFF2E7D32),
                iconColor: const Color(0xFF2E7D32),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                showDivider: false,
              ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _checkLoginAndNavigate(BuildContext context, Widget screen) {
    if (user == null) {
      _showLoginRequiredDialog(context);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    DialogHelper.showLoginRequired(
      context: context,
      onLogin: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
            child: const Icon(Icons.person, color: Color(0xFF2E7D32), size: 35),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: user != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user!.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        user!.phoneNumber ?? user!.username,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "KHÁCH VÃNG LAI",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Đăng nhập để trải nghiệm đầy đủ",
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
