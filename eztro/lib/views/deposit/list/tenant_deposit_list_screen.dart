import 'package:flutter/material.dart';
import '../../../core/utils/format_helper.dart';
import '../../../services/deposit_service.dart';
import '../../../services/auth_service.dart';
import '../detail/tenant_deposit_qr_screen.dart';
import '../detail/deposit_detail_screen.dart';
import '../../../models/deposit_model.dart';
import '../../../core/constants/app_colors.dart';
import 'package:eztro/core/widgets/widgets.dart';

class TenantDepositListScreen extends StatefulWidget {
  const TenantDepositListScreen({super.key});

  @override
  State<TenantDepositListScreen> createState() =>
      _TenantDepositListScreenState();
}

class _TenantDepositListScreenState extends State<TenantDepositListScreen> {
  List<DepositModel> _deposits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeposits();
  }

  Future<void> _loadDeposits() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final data = await DepositService.getTenantDeposits(user.id);
    if (mounted) {
      setState(() {
        _deposits = data;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'waiting_payment':
        return Colors.amber;
      case 'pending':
        return Colors.blue;
      case 'confirmed':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'waiting_payment':
        return 'Chờ thanh toán';
      case 'pending':
        return 'Đã thanh toán';
      case 'confirmed':
      case 'completed':
        return 'Đã nhận phòng';
      case 'cancelled':
        return 'Đã hủy';
      case 'expired':
        return 'Hết hạn';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'waiting_payment':
        return Icons.hourglass_top_rounded;
      case 'pending':
        return Icons.check_circle_outline;
      case 'confirmed':
      case 'completed':
        return Icons.verified_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'expired':
        return Icons.timer_off_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'LỊCH SỬ ĐẶT CỌC',
        onBack: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _deposits.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadDeposits,
              color: AppColors.primary,
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _deposits.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.8,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.black.withOpacity(0.22),
                ),
                itemBuilder: (context, index) =>
                    _buildDepositCard(_deposits[index]),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Chưa có đơn đặt cọc nào",
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tìm phòng ưng ý và đặt cọc ngay!",
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositCard(DepositModel deposit) {
    final status = deposit.status;
    final statusColor = _getStatusColor(status);
    final amount = deposit.depositAmount;
    final isWaiting = status == 'waiting_payment';

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showDepositDetail(deposit),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Text(
                            "Phòng ${deposit.roomName}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF263238),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 32),
                        const Expanded(
                          flex: 4,
                          child: Text(
                            "Dự kiến vào:",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- CỘT TRÁI ---
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(26),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getStatusText(status).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CardInfoRow(
                                  icon: Icons.person_outline,
                                  text: deposit.customerName ?? "Trống",
                                  textColor: Colors.black,
                                ),
                                const SizedBox(height: 8),
                                CardInfoRow(
                                  icon: Icons.home_outlined,
                                  text: deposit.houseName ?? "N/A",
                                ),
                                const SizedBox(height: 8),
                                CardInfoRow(
                                  icon: Icons.monetization_on_outlined,
                                  text: CurrencyHelper.formatVND(amount),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          // --- CỘT PHẢI ---
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  deposit.expectedMoveInDate ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text("Ngày đặt:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 6),
                                    Text(
                                      deposit.depositDate,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Nút thanh toán nếu đang chờ
                    if (isWaiting) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () => _reopenPayment(deposit),
                          icon: const Icon(Icons.qr_code_scanner, size: 18),
                          label: const Text(
                            "Tiếp tục thanh toán",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[800],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDepositDetail(DepositModel deposit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepositDetailScreen(depositId: deposit.id),
      ),
    ).then((_) => _loadDeposits());
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reopenPayment(DepositModel deposit) {
    final String? checkoutUrl = deposit.checkoutUrl;
    final String? expiresAt = deposit.paymentExpiresAt;
    final double amount = deposit.depositAmount;
    final int depositId = deposit.id;

    // Nếu không có checkout_url
    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Không tìm thấy link thanh toán. Vui lòng tạo đơn cọc mới.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mở lại màn hình thanh toán
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TenantDepositQrScreen(
          depositId: depositId,
          checkoutUrl: checkoutUrl,
          qrCode: deposit.qrCode,
          expiresAt: expiresAt ?? '',
          amount: amount.toInt(),
          roomName: deposit.roomName ?? 'N/A',
          houseName: deposit.houseName ?? 'N/A',
          bankBin: deposit.bankBin,
          bankAccountNumber: deposit.bankAccountNumber,
          bankAccountName: deposit.bankAccountName,
          paymentDescription: deposit.paymentDescription,
        ),
      ),
    ).then((_) => _loadDeposits()); // Refresh sau khi quay lại
  }
}
