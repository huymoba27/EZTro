import 'package:eztro/views/home/home_screen.dart';
import 'package:eztro/views/home/tenant_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/input_validation_helper.dart';
import 'role_selection_screen.dart';
import 'providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final res = await ref
          .read(authProvider.notifier)
          .register(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
          );

      if (!mounted) return;

      if (res['status'] == 'success') {
        final role = res['role'];
        DialogHelper.showSuccess(
          context,
          "Đăng ký thành công!",
          onTap: () {
            Widget destination;
            if (role == null || role == 'unassigned') {
              destination = const RoleSelectionScreen();
            } else if (role != 'tenant') {
              destination = const HomeScreen();
            } else {
              destination = const TenantHomeScreen();
            }

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => destination),
              (route) => false,
            );
          },
        );
      } else {
        DialogHelper.showError(context, res['message'] ?? "Đăng ký thất bại");
      }
    } catch (e) {
      DialogHelper.showError(context, "Lỗi kết nối: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Tạo tài khoản mới",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Bắt đầu hành trình quản lý trọ thông minh cùng EZTro ngay hôm nay.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 40),

                _buildModernField(
                  controller: _fullNameController,
                  label: "Họ và tên *",
                  icon: Icons.badge_outlined,
                  validator: (v) => v!.isEmpty ? "Vui lòng nhập họ tên" : null,
                ),
                const SizedBox(height: 20),

                _buildModernField(
                  controller: _usernameController,
                  label: "Tên đăng nhập *",
                  icon: Icons.account_circle_outlined,
                  validator: (v) =>
                      v!.length < 5 ? "Tên đăng nhập tối thiểu 5 ký tự" : null,
                ),
                const SizedBox(height: 20),

                _buildModernField(
                  controller: _phoneController,
                  label: "Số điện thoại *",
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 11,
                  validator: (v) => InputValidationHelper.phoneError(v ?? ""),
                ),
                const SizedBox(height: 20),

                _buildModernField(
                  controller: _passwordController,
                  label: "Mật khẩu *",
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: !_isPasswordVisible,
                  onToggleVisibility: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                  validator: (v) =>
                      v!.length < 6 ? "Mật khẩu tối thiểu 6 ký tự" : null,
                ),

                const SizedBox(height: 50),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "ĐĂNG KÝ NGAY",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Đã có tài khoản?",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          " Đăng nhập",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF263238),
      ),
      decoration: InputDecoration(
        labelText: label,
        counterText: maxLength == null ? null : "",
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
      ),
    );
  }
}
