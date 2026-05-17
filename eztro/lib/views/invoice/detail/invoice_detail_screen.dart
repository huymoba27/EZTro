import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/auth_service.dart';
import '../../payment/create/payos_payment_screen.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/dialog_helper.dart';
import '../providers/invoice_notifier.dart';
import '../../../services/invoice_service.dart';
import '../../../models/invoice_model.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final InvoiceModel? invoice;
  final int? invoiceId;

  const InvoiceDetailScreen({super.key, this.invoice, this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  InvoiceModel? currentInvoice;
  final currencyFormat = NumberFormat("#,###", "vi_VN");
  bool isUpdating = false;
  bool isLoading = false;
  String userRole = 'landlord';

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      currentInvoice = widget.invoice;
    }
    // Luôn tải lại chi tiết để lấy Nhật ký (Logs) và dữ liệu mới nhất
    _loadInvoice();
    _checkRole();
  }

  Future<void> _loadInvoice() async {
    final idToFetch = widget.invoiceId ?? widget.invoice?.id;
    if (idToFetch == null) return;

    setState(() => isLoading = true);
    final data = await InvoiceService.getInvoiceDetail(idToFetch);
    if (mounted) {
      setState(() {
        currentInvoice = data;
        isLoading = false;
      });
    }
  }

  Future<void> _checkRole() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() => userRole = user?.role ?? 'landlord');
    }
  }

  String _formatMoney(dynamic amount) {
    if (amount == null || amount.toString().isEmpty) return "0";
    try {
      double val = double.parse(amount.toString());
      return currencyFormat.format(val.toInt());
    } catch (e) {
      return "0";
    }
  }

  void _changeStatus() {
    if (userRole == 'tenant') return;
    bool isPaid = currentInvoice!.status == 'paid';

    DialogHelper.showReasonDialog(
      context: context,
      title: isPaid ? "HỦY THANH TOÁN" : "XÁC NHẬN THU TIỀN",
      subtitle: isPaid
          ? "Hành động này sẽ chuyển hóa đơn về trạng thái chờ"
          : "Hệ thống sẽ ghi nhận bạn đã thu tiền hóa đơn này",
      hintText: isPaid
          ? "Nhập lý do hoàn tác (Bắt buộc)..."
          : "Ghi chú thêm (Ví dụ: Thu tiền mặt, Chuyển khoản...)",
      confirmText: isPaid ? "XÁC NHẬN" : "XÁC NHẬN",
      confirmColor: isPaid ? Colors.orange : AppColors.primary,
      isRequired: isPaid, // Bắt buộc nhập lý do nếu chuyển từ Paid -> Pending
      onConfirm: (reason) async {
        String newStatus = isPaid ? 'pending' : 'paid';

        setState(() => isUpdating = true);
        final res = await ref
            .read(invoiceNotifierProvider.notifier)
            .updateStatus(currentInvoice!.id, newStatus, reason: reason);
        setState(() => isUpdating = false);

        if (res['status'] == 'success') {
          // Tải lại toàn bộ hóa đơn để lấy Nhật ký mới nhất từ Server
          _loadInvoice();
          DialogHelper.showSuccess(context, "Cập nhật trạng thái thành công!");
        } else {
          DialogHelper.showError(
            context,
            res['message'] ?? "Lỗi cập nhật server",
          );
        }
      },
    );
  }

  void _handleDelete() {
    DialogHelper.showConfirmDialog(
      context: context,
      title: "XÓA HÓA ĐƠN",
      message:
          "Bạn có chắc chắn muốn xóa hóa đơn #${currentInvoice!.id} không?",
      onConfirm: () async {
        setState(() => isUpdating = true);
        final res = await ref
            .read(invoiceNotifierProvider.notifier)
            .deleteInvoice(currentInvoice!.id);
        setState(() => isUpdating = false);

        if (res['status'] == 'success') {
          if (mounted) {
            DialogHelper.showSuccess(
              context,
              res['message'] ?? "Xóa hóa đơn thành công",
              onTap: () {
                if (mounted) Navigator.pop(context, true);
              },
            );
          }
        } else {
          if (mounted) {
            DialogHelper.showError(context, res['message'] ?? "Không thể xóa");
          }
        }
      },
    );
  }

  void _handleTenantPayment() async {
    final bool? success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PayOSPaymentScreen(invoice: currentInvoice!),
      ),
    );
    if (success == true) {
      setState(() {
        currentInvoice = InvoiceModel.fromJson({
          ...currentInvoice!.toJson(),
          'status': 'paid',
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: CustomAppBar(
        title: "CHI TIẾT HÓA ĐƠN",
        onBack: () => Navigator.pop(context),
      ),
      body: (isLoading || currentInvoice == null)
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // --- STATUS BANNER ---
                            _buildStatusBanner(),

                            // --- INFO SECTION ---
                            _buildInfoSection(),

                            Container(
                              height: 8,
                              color: const Color(0xFFF2F2F7),
                            ),

                            // --- FEE BREAKDOWN ---
                            _buildFeeBreakdown(),

                            Container(
                              height: 8,
                              color: const Color(0xFFF2F2F7),
                            ),

                            // --- ACTIVITY HISTORY ---
                            _buildActivityHistory(),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // --- BOTTOM ACTION BAR ---
                    _buildBottomButtons(),
                  ],
                ),
                if (isUpdating)
                  Container(
                    color: Colors.black12,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildStatusBanner() {
    bool isPaid = currentInvoice!.status == 'paid';
    bool isBadDebt = currentInvoice!.status == 'bad_debt';

    Color statusColor;
    Color statusBg;
    String statusText;

    if (isPaid) {
      statusColor = const Color(0xFF2E7D32);
      statusBg = const Color(0xFFE8F5E9);
      statusText = "ĐÃ THANH TOÁN";
    } else if (isBadDebt) {
      statusColor = const Color(0xFF880E4F); // Dark Red
      statusBg = const Color(0xFFFCE4EC); // Light Pink
      statusText = "THẤT THU";
    } else {
      statusColor = Colors.orange;
      statusBg = const Color(0xFFFFF3E0);
      statusText = "CHƯA THANH TOÁN";
    }

    return Container(
      width: double.infinity,
      color: statusBg,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${_formatMoney(currentInvoice!.totalAmount)} đ",
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
          if (!isPaid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Ngày lập: ${currentInvoice!.createdAt.split(' ')[0]}",
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return AppSectionCard(
      title: "Thông tin chung",
      child: Column(
        children: [
          DetailInfoRow(label: "Mã hóa đơn", value: "#${currentInvoice!.id}"),
          const DetailDividerWidget(),
          DetailInfoRow(
            label: "Kỳ hóa đơn",
            value:
                "Tháng ${currentInvoice!.billingMonth}/${currentInvoice!.billingYear}",
          ),
          const DetailDividerWidget(),
          DetailInfoRow(
            label: "Nhà trọ",
            value: currentInvoice!.houseName ?? "--",
          ),
          const DetailDividerWidget(),
          DetailInfoRow(
            label: "Phòng trọ",
            value: "Phòng ${currentInvoice!.roomName}",
          ),
        ],
      ),
    );
  }

  Widget _buildFeeBreakdown() {
    return AppSectionCard(
      title: "Chi tiết bảng kê",
      child: Column(
        children: [
          _buildMainFeeItem("Tiền phòng", currentInvoice!.roomAmount),

          ...currentInvoice!.details
              .where((item) {
                final name = item.name.toLowerCase();
                return !(name == 'tiền phòng' || name.startsWith('tiền phòng'));
              })
              .map((item) {
                return _buildServiceFeeItem(item);
              }),

          const Divider(height: 32, thickness: 1, color: Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TỔNG CỘNG",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF263238),
                ),
              ),
              Text(
                "${_formatMoney(currentInvoice!.totalAmount)} đ",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    bool isPaid = currentInvoice!.status == 'paid';
    bool isBadDebt = currentInvoice!.status == 'bad_debt';

    // Ẩn toàn bộ nút thao tác nếu là Thất thu (tránh thao tác nhầm vào dữ liệu chốt sổ)
    if (isBadDebt) {
      return const SizedBox.shrink();
    }

    if (userRole != 'tenant') {
      return AppBottomButtons(
        onCancel: _handleDelete,
        onConfirm: _changeStatus,
        cancelText: "XÓA",
        confirmText: isPaid ? "CHƯA THU" : "XÁC NHẬN THU",
        confirmColor: isPaid ? Colors.grey : AppColors.primary,
        isSubmitting: isUpdating,
      );
    } else {
      if (isPaid) return const SizedBox.shrink();
      return AppBottomButtons(
        onConfirm: _handleTenantPayment,
        confirmText: "THANH TOÁN NGAY",
        confirmColor: const Color(0xFF2E7D32),
        showCancel: false,
        isSubmitting: isUpdating,
      );
    }
  }

  Widget _buildActivityHistory() {
    if (currentInvoice!.logs.isEmpty) return const SizedBox.shrink();

    return AppSectionCard(
      title: "Lịch sử hoạt động",
      child: Column(
        children: currentInvoice!.logs.map((log) {
          bool isPaid = log.newStatus == 'paid';
          bool isCreate = log.oldStatus.isEmpty;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(
                      isPaid
                          ? Icons.check_circle
                          : isCreate
                          ? Icons.post_add
                          : Icons.history,
                      color: isPaid
                          ? Colors.green
                          : isCreate
                          ? Colors.blue
                          : Colors.orange,
                      size: 20,
                    ),
                    if (log != currentInvoice!.logs.last)
                      Container(
                        width: 2,
                        height: 40,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.grey.shade200,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${log.userName} (${log.userRole == 'landlord' ? 'Chủ trọ' : 'Quản lý'})",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPaid
                            ? "Đã xác nhận thanh toán"
                            : "Đã chuyển về trạng thái chờ",
                        style: TextStyle(
                          color: isPaid ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (log.reason != null && log.reason!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 6, bottom: 4),
                          padding: const EdgeInsets.all(10),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Lý do: ${log.reason}",
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        log.createdAt,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainFeeItem(String label, dynamic amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            "${_formatMoney(amount)} đ",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceFeeItem(InvoiceDetailModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.split(' (')[0],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.name.contains('(')
                      ? "${item.quantity}${item.unit} x ${_formatMoney(item.unitPrice)}đ"
                      : "${item.quantity} ${item.unit} x ${_formatMoney(item.unitPrice)}đ",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            "${_formatMoney(item.subtotal)} đ",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
