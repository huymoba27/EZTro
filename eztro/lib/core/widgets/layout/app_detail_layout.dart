import 'package:flutter/material.dart';

/// Khung layout chuẩn cho các BottomSheet chi tiết (Room, Vehicle, Incident...)
class AppDetailLayout extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? headerImage;

  const AppDetailLayout({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.headerImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar (Gạch ngang nhỏ)
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Center(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Content
          ...children,

          // Optional Image
          if (headerImage != null) ...[
            //const Divider(height: 32, color: Color(0xFFF5F5F5)),
            const SizedBox(height: 16),
            headerImage!,
          ],

          // Actions
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 30),
            Row(children: actions!),
          ],

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
