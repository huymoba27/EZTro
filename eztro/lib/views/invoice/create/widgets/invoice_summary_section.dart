import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eztro/core/widgets/widgets.dart';

class InvoiceSummarySection extends StatelessWidget {
  final Map<String, dynamic> billSummary;
  final bool isMeterChecked;
  final NumberFormat currencyFormat;

  const InvoiceSummarySection({
    super.key,
    required this.billSummary,
    required this.isMeterChecked,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: "Chi tiết hóa đơn",
      child: Column(
        children: [
          ...(billSummary['details'] as List).map((item) => _buildDetailRow(item)),
          const Divider(height: 30, thickness: 0.8),
          _priceRow(
            isMeterChecked ? "TỔNG CỘNG" : "TỔNG TẠM TÍNH",
            billSummary['total_amount'],
            isBold: true,
            color: Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A1A)),
                ),
                Text(
                  "SL: ${item['quantity']} ${item['unit'] ?? ''} x ${currencyFormat.format(item['price'])}đ",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            "${currencyFormat.format(item['subtotal'])}đ",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF263238)),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, dynamic price, {bool isBold = false, Color color = Colors.black87}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? Colors.black : Colors.black54,
          ),
        ),
        Text(
          "${currencyFormat.format(price)}đ",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }
}
