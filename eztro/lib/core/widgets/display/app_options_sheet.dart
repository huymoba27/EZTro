import 'package:flutter/material.dart';

/// Widget hiển thị danh sách các tùy chọn (Sửa, Xóa...) chuẩn Design System.
class AppOptionsSheet extends StatelessWidget {
  final String title;
  final List<AppOptionItem> options;

  const AppOptionsSheet({
    super.key,
    this.title = "TÙY CHỌN",
    required this.options,
  });

  static void show({
    required BuildContext context,
    String title = "TÙY CHỌN",
    required List<AppOptionItem> options,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AppOptionsSheet(title: title, options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Center(
                    child: Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Options List
          ...options.map((option) => _buildOptionTile(context, option)),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, AppOptionItem option) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        option.onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              option.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: option.isDestructive ? Colors.red[400] : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppOptionItem {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  AppOptionItem({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}
