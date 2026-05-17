import 'package:flutter/material.dart';
import '../../../services/expense_service.dart';
import '../../../core/utils/format_helper.dart';
import '../../../core/utils/receipt_type_helper.dart';
import 'package:eztro/core/widgets/widgets.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final int expenseId;
  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  Map<String, dynamic>? data;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final res = await ExpenseService.getExpenseDetail(widget.expenseId);
    if (mounted) setState(() { data = res; isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Scaffold(appBar: CustomAppBar(title: "CHI TIẾT PHIẾU CHI", onBack: () => Navigator.pop(context)), body: const Center(child: CircularProgressIndicator()));
    if (data == null || data!.isEmpty || (data!.containsKey('status') && data!['status'] == 'error')) {
      return Scaffold(appBar: CustomAppBar(title: "CHI TIẾT PHIẾU CHI", onBack: () => Navigator.pop(context)), body: const Center(child: Text("Không tìm thấy dữ liệu hoặc lỗi tải")));
    }

    final amount = double.tryParse(data!['amount']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: CustomAppBar(
        title: "CHI TIẾT PHIẾU CHI",
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- STATUS BANNER ---
            Container(
              width: double.infinity,
              color: const Color(0xFFFFEBEE),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  const Text(
                    "XUẤT QUỸ / CHI PHÍ",
                    style: TextStyle(
                      color: Color(0xFFD32F2F),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "-${CurrencyHelper.formatVND(amount)}",
                    style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                    ),
                  ),
                ],
              ),
            ),

            // --- INFO SECTION ---
            AppSectionCard(
              title: "Thông tin chứng từ",
              child: Column(
                children: [
                  _buildFlatInfoRow("Mã chứng từ", "#EXP${data!['id']}"),
                  _buildFlatInfoRow("Người nhận", data!['receiver_name'] ?? 'N/A'),
                  _buildFlatInfoRow("Khu trọ", data!['house_name'] ?? 'N/A'),
                  _buildFlatInfoRow("Phòng liên quan", data!['room_name'] ?? 'Chi chung'),
                  _buildFlatInfoRow("Ngày chi", data!['expense_date']),
                  _buildFlatInfoRow("Phương thức", data!['payment_method'] ?? 'Tiền mặt'),
                  _buildFlatInfoRow(
                    "Loại chi phí",
                    ReceiptTypeHelper.toVietnamese(data!['expense_type'], isReceipt: false),
                    isLast: true,
                  ),
                ],
              ),
            ),

            if (data!['description'] != null && data!['description'].toString().isNotEmpty)
              AppSectionCard(
                title: "Ghi chú nội dung",
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    data!['description'],
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                  ),
                ),
              ),

            const SizedBox(height: 32),
            Text(
              "Vui lòng lưu chứng từ để đối soát",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatInfoRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF263238),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 0.5, color: Colors.grey[200]),
      ],
    );
  }
}
