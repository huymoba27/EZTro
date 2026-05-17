import 'package:eztro/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/format_helper.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../services/contract_service.dart';

class TerminateContractScreen extends StatefulWidget {
  final int contractId;
  final Map<String, dynamic>? initialData;
  const TerminateContractScreen({
    super.key,
    required this.contractId,
    this.initialData,
  });

  @override
  State<TerminateContractScreen> createState() =>
      _TerminateContractScreenState();
}

class _TerminateContractScreenState extends State<TerminateContractScreen> {
  bool isLoading = true;
  Map<String, dynamic>? settlementData;

  // Các khoản trừ
  final TextEditingController penaltyController = TextEditingController();
  final TextEditingController damageController = TextEditingController();
  final TextEditingController cleaningController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  double actualRefund = 0;
  double potentialLoss = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      settlementData = widget.initialData;
      isLoading = false;
      _calculateRefund();
    } else {
      _fetchPreview();
    }

    // Listen to changes to recalculate refund
    penaltyController.addListener(_calculateRefund);
    damageController.addListener(_calculateRefund);
    cleaningController.addListener(_calculateRefund);
  }

  @override
  void dispose() {
    penaltyController.dispose();
    damageController.dispose();
    cleaningController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchPreview() async {
    final res = await ContractService.getSettlementPreview(widget.contractId);
    if (mounted) {
      if (res['status'] == 'success') {
        setState(() {
          settlementData = res['data'];
          isLoading = false;
        });
        _calculateRefund();
      } else {
        DialogHelper.showError(context, res['message'] ?? "Lỗi tải dữ liệu");
        Navigator.pop(context);
      }
    }
  }

  void _calculateRefund() {
    if (settlementData == null) return;

    double deposit =
        double.tryParse(settlementData!['deposit_amount']?.toString() ?? '0') ??
        0;
    double unpaidTotal =
        double.tryParse(settlementData!['total_debt']?.toString() ?? '0') ?? 0;

    double penalty = double.tryParse(penaltyController.text) ?? 0;
    double damage = double.tryParse(damageController.text) ?? 0;
    double cleaning = double.tryParse(cleaningController.text) ?? 0;

    double totalDeductions = unpaidTotal + penalty + damage + cleaning;

    setState(() {
      actualRefund = (deposit - totalDeductions).clamp(0, double.infinity);
      potentialLoss = (totalDeductions - deposit).clamp(0, double.infinity);
    });
  }

  Future<void> _handleTerminate() async {
    final hasInvoiceThisMonth =
        settlementData?['has_invoice_this_month'] == true;
    if (!hasInvoiceThisMonth) {
      DialogHelper.showError(
        context,
        "Chưa lập hóa đơn tháng cuối. Vui lòng lập hóa đơn để chốt chỉ số trước khi thanh lý.",
      );
      return;
    }

    DialogHelper.showConfirmDialog(
      context: context,
      title: "THANH LÝ",
      message:
          "Hệ thống sẽ dùng tiền cọc để thanh toán các khoản nợ và phí phát sinh. Bạn có chắc chắn muốn hoàn tất thanh lý không?",
      onConfirm: () async {
        setState(() => isLoading = true);

        final res = await ContractService.terminateContract(
          contractId: widget.contractId,
          penalty: double.tryParse(penaltyController.text) ?? 0,
          damage: double.tryParse(damageController.text) ?? 0,
          cleaning: double.tryParse(cleaningController.text) ?? 0,
          reason: reasonController.text,
        );

        setState(() => isLoading = false);

        if (res['status'] == 'success') {
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            DialogHelper.showError(context, res['message'] ?? "Lỗi server");
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: CustomAppBar(
          title: "THANH LÝ HỢP ĐỒNG",
          onBack: () => Navigator.pop(context),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: CustomAppBar(
        title: "THANH LÝ TẤT TOÁN",
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildGeneralInfo(),
            const SizedBox(height: 8),
            _buildDebtSection(),
            const SizedBox(height: 8),
            _buildAdjustmentSection(),
            const SizedBox(height: 8),
            _buildSummarySection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomButtons(
        confirmText: "THANH LÝ",
        onConfirm: _handleTerminate,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildGeneralInfo() {
    return AppSectionCard(
      title: "Thông tin tất toán",
      child: Column(
        children: [
          DetailRowWidget(
            icon: Icons.person_outline,
            label: "Khách thuê",
            value: settlementData!['tenant_name'],
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.meeting_room_outlined,
            label: "Phòng",
            value:
                "${settlementData!['room_name']} (${settlementData!['house_name']})",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.account_balance_wallet_outlined,
            label: "Tiền đặt cọc",
            value: CurrencyHelper.formatVND(settlementData!['deposit_amount']),
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDebtSection() {
    List unpaidInvoices = settlementData!['unpaid_invoices'] ?? [];
    double totalDebt =
        double.tryParse(settlementData!['total_debt']?.toString() ?? '0') ?? 0;

    return AppSectionCard(
      title: "Công nợ hiện tại",
      child: Column(
        children: [
          if (unpaidInvoices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "Không có hóa đơn nợ",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else ...[
            ...unpaidInvoices.map(
              (inv) => Column(
                children: [
                  DetailRowWidget(
                    icon: Icons.receipt_long_outlined,
                    label:
                        "Hóa đơn tháng ${inv['billing_month']}/${inv['billing_year']}",
                    value: CurrencyHelper.formatVND(inv['total_amount']),
                    valueColor: Colors.red[700],
                  ),
                  const DetailDividerWidget(),
                ],
              ),
            ),
            DetailRowWidget(
              icon: Icons.summarize_outlined,
              label: "TỔNG NỢ HÓA ĐƠN",
              value: CurrencyHelper.formatVND(totalDebt),
              valueColor: Colors.red[900],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdjustmentSection() {
    return AppSectionCard(
      title: "Chi phí phát sinh & Phạt",
      child: Column(
        children: [
          CustomTextField(
            label: "Tiền phạt vi phạm (đ)",
            controller: penaltyController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: "Tiền hư hại thiết bị (đ)",
            controller: damageController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: "Phí vệ sinh phòng (đ)",
            controller: cleaningController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: "Lý do / Ghi chú",
            controller: reasonController,
            hint: "Nhập lý do thanh lý (nếu có)...",
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    bool isRefund = actualRefund > 0;
    return AppSectionCard(
      title: "TỔNG KẾT TẤT TOÁN",
      child: Column(
        children: [
          DetailRowWidget(
            icon: isRefund
                ? Icons.assignment_return_outlined
                : Icons.money_off_outlined,
            label: isRefund
                ? "Số tiền hoàn trả khách"
                : "Tổng thất thu (nợ xấu)",
            value: isRefund
                ? CurrencyHelper.formatVND(actualRefund)
                : CurrencyHelper.formatVND(potentialLoss),
            valueColor: isRefund ? Colors.green[700] : Colors.red[700],
          ),
          if (potentialLoss > 0)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  "Tiền cọc không đủ bù đắp nợ",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          if (settlementData?['has_invoice_this_month'] == false)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  "Chưa có hóa đơn tháng cuối",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
