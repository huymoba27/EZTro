import 'package:flutter/material.dart';

/// Widget Badge trạng thái dùng chung cho toàn bộ dự án.
/// Hỗ trợ: Room, Incident, Contract, Post, Invoice, Deposit...
/// Sử dụng: `AppStatusBadge(status: 'pending')` hoặc `AppStatusBadge(status: 'empty')`
class AppStatusBadge extends StatelessWidget {
  final String status;
  final int? current;
  final int? max;

  const AppStatusBadge({
    super.key,
    required this.status,
    this.current,
    this.max,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withAlpha(26),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        config.label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          color: config.color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      // === Room ===
      case 'full':
        return _StatusConfig(label: "Đã đầy", color: const Color(0xFFFF5252));
      case 'deposited':
        return _StatusConfig(label: "Đã cọc", color: Colors.blue);
      case 'available':
      case 'occupied':
        return _StatusConfig(label: "Đang ở", color: const Color(0xFFFFA000));
      case 'fixing':
        return _StatusConfig(label: "Bảo trì", color: Colors.grey);
      case 'empty':
        return _StatusConfig(label: "Trống", color: const Color(0xFF4CAF50));

      // === Incident ===
      case 'processing':
        return _StatusConfig(label: "Đang xử lý", color: Colors.orange);
      case 'resolved':
        return _StatusConfig(label: "Đã xong", color: Colors.green);

      // === Contract ===
      case 'active':
        return _StatusConfig(label: "Hiệu lực", color: Colors.green);
      case 'expired':
        return _StatusConfig(label: "Hết hạn", color: Colors.red);
      case 'terminated':
      case 'ended':
        return _StatusConfig(label: "Đã kết thúc", color: Colors.grey);

      // === Post ===
      case 'visible':
        return _StatusConfig(label: "Đang hiển thị", color: Colors.green);
      case 'hidden':
        return _StatusConfig(label: "Đã ẩn", color: Colors.grey);

      // === Invoice ===
      case 'paid':
        return _StatusConfig(label: "Đã thu", color: Colors.green);
      case 'pending':
      case 'unpaid':
        return _StatusConfig(label: "Chưa thu", color: Colors.red);
      case 'partially_paid':
      case 'partial':
        return _StatusConfig(label: "Thu một phần", color: Colors.orange);
      case 'bad_debt':
        return _StatusConfig(label: "Thất thu", color: const Color(0xFF880E4F));

      // === Deposit ===
      case 'holding':
        return _StatusConfig(label: "Đang giữ", color: Colors.blue);
      case 'refunded':
        return _StatusConfig(label: "Đã trả", color: Colors.green);
      case 'forfeited':
        return _StatusConfig(label: "Đã thu", color: Colors.red);

      default:
        return _StatusConfig(label: status.toUpperCase(), color: Colors.grey);
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  _StatusConfig({required this.label, required this.color});
}
