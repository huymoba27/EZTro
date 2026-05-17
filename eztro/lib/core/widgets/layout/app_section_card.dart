import 'package:flutter/material.dart';
import '../../constants/app_design.dart';
import '../../constants/app_colors.dart';

/// Widget tiêu đề section với thanh màu bên trái.
class AppSectionTitle extends StatelessWidget {
  final String title;
  final bool isUppercase;

  const AppSectionTitle({
    super.key,
    required this.title,
    this.isUppercase = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isUppercase ? title.toUpperCase() : title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget bọc nội dung trong 1 section card.
class AppSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  final bool showTitle;

  const AppSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesign.sectionPadding),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: []),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppSectionTitle(title: title),
                ?action,
              ],
            ),
          if (showTitle) const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
