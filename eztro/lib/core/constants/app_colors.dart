import 'package:flutter/material.dart';

class AppColors {
  // Thương hiệu chung (Colors.teal / Green mix)
  static const Color primary = Color(0xFF2E7D32);       // Xanh rêu đậm (Giống gradient của bạn)
  static const Color primaryLight = Color(0xFF4CAF50);  // Xanh rêu nhạt
  static const Color secondary = Color(0xFF009688);     // Xanh cổ vịt (Teal)

  // Nền ứng dụng
  static const Color background = Colors.white;         // Trở về nền trắng gốc
  static const Color surface = Colors.white;            // Dành cho Card, Dialog...

  // Text
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF757575);

  // Gradient chính cho AppBar
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
