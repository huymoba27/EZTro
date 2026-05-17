import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dialog_helper.dart';
import '../home/home_screen.dart';
import '../home/tenant_home_screen.dart';
import 'register_screen.dart';
import 'role_selection_screen.dart';
import 'providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final res = await ref.read(authProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
          );

      if (!mounted) return;

      if (res['status'] == 'success') {
        final role = res['role'];
        
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
      } else {
        DialogHelper.showError(context, res['message'] ?? "Sai tài khoản hoặc mật khẩu");
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
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Top Background Decoration
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),
                  
                  // Logo
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.home_work_rounded,
                          size: 50, color: AppColors.primary),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  const Text(
                    "Xin chào bạn!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Chào mừng bạn quay trở lại với EZTro.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildModernField(
                          controller: _usernameController,
                          label: "Số điện thoại / Tài khoản",
                          icon: Icons.person_outline,
                          validator: (v) => v!.isEmpty ? "Vui lòng nhập tài khoản" : null,
                        ),
                        const SizedBox(height: 20),
                        _buildModernField(
                          controller: _passwordController,
                          label: "Mật khẩu",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscureText: !_isPasswordVisible,
                          onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          validator: (v) => v!.isEmpty ? "Vui lòng nhập mật khẩu" : null,
                        ),
                        
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                            child: const Text("Quên mật khẩu?", style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Login Button
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
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      "ĐĂNG NHẬP",
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
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Chưa có tài khoản?",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        ),
                        child: const Text(
                          " Đăng ký ngay",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF263238)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }
}
