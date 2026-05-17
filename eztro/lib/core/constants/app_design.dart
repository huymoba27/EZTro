import 'package:flutter/material.dart';

/// Hằng số thiết kế dùng chung cho toàn bộ ứng dụng.
/// Tập trung quản lý khoảng cách, viền, bán kính để đảm bảo
/// tính nhất quán UI trên mọi màn hình.
class AppDesign {
  AppDesign._();

  // Spacing
  static const double screenMargin = 16.0;
  static const double sectionPadding = 16.0;

  // Border
  static const double borderWidth = 0.8;
  static const Color borderBaseColor = Color(0xFFE0E0E0);
  static final BorderRadius borderRadius8 = BorderRadius.circular(8);
  static final BorderRadius borderRadius12 = BorderRadius.circular(12);
}
