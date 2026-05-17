import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Widget hiển thị 1 dòng icon + text trong Card danh sách (compact).
class CardInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final Color? textColor;

  const CardInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: iconColor ?? Colors.black38,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: textColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget hiển thị 1 dòng icon + label + value trong màn hình chi tiết.
class DetailRowWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;
  final Widget? customValueWidget;

  const DetailRowWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
    this.customValueWidget,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: effectiveIconColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: effectiveIconColor),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: customValueWidget ??
                Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị Key-Value trong Card (Compact).
class CardKeyValueRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const CardKeyValueRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor ?? Colors.black38),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị 1 dòng nhãn + giá trị (không icon) dùng trong Modal.
class DetailInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const DetailInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Divider chuẩn dùng trong các màn hình chi tiết.
class DetailDividerWidget extends StatelessWidget {
  const DetailDividerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: Colors.black.withOpacity(0.15),
    );
  }
}
