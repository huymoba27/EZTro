import 'package:flutter/material.dart';

/// Widget dùng chung để làm dải ngăn cách giữa các item trong danh sách (ListView.separated)
/// Giúp đảm bảo tính nhất quán về độ cao và màu sắc trên toàn ứng dụng.
class AppListSeparator extends StatelessWidget {
  final double height;
  final Color color;

  const AppListSeparator({
    super.key,
    this.height = 4,
    this.color = const Color(0xFFF2F2F7),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: color,
    );
  }
}
