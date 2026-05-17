import 'package:flutter/material.dart';

class FormSection extends StatelessWidget {
  final String step;
  final String title;
  final String sub;
  final Color color;
  final Widget child;
  final double? verticalPadding; // Thêm tùy chọn để chỉnh nếu cần

  const FormSection({
    super.key,
    required this.step,
    required this.title,
    required this.sub,
    required this.color,
    required this.child,
    this.verticalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Thêm khoảng cách giữa các Section
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            width: double.infinity,
            color: const Color(0xFFF8F9FA),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: color, 
                radius: 12, 
                child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5, color: Color(0xFF1E1E1E))),
                  Text(sub, style: const TextStyle(color: Color(0xFF757575), fontSize: 12)),
                ]),
              )
            ]),
          ),
          // Khối trắng chứa nội dung
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding ?? 24), // Tăng padding dọc lên 24
            width: double.infinity,
            child: child,
          ),
        ],
      ),
    );
  }
}