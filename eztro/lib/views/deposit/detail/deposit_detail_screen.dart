import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/deposit_service.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/format_helper.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../contract/create/create_contract_screen.dart';
import '../create/create_deposit_screen.dart';
import '../../../models/deposit_model.dart';

class DepositDetailScreen extends StatefulWidget {
  final int depositId;
  const DepositDetailScreen({super.key, required this.depositId});

  @override
  State<DepositDetailScreen> createState() => _DepositDetailScreenState();
}

class _DepositDetailScreenState extends State<DepositDetailScreen> {
  DepositModel? depositData;
  bool isLoading = true;
  String userRole = 'landlord';

  @override
  void initState() {
    super.initState();
    _fetchDetail();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() => userRole = user?.role ?? 'landlord');
    }
  }

  Future<void> _fetchDetail() async {
    final data = await DepositService.getDepositDetail(widget.depositId);
    if (mounted) {
      setState(() {
        depositData = data;
        isLoading = false;
      });
    }
  }

  void _cancelDeposit() {
    if (depositData == null) return;
    final amountController = TextEditingController(
      text: depositData!.depositAmount.toInt().toString(),
    );
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          "HỦY PHIẾU CỌC",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bạn chắc chắn muốn hủy phiếu cọc này?"),
            const SizedBox(height: 18),
            CustomTextField(
              controller: amountController,
              label: "Số tiền hoàn lại cho khách",
              hint: "Số tiền hoàn lại (VNĐ)",
              keyboardType: TextInputType.number,
            ),
            CustomTextField(
              controller: reasonController,
              label: "Lý do hủy",
              hint: "Ví dụ: Khách đổi ý, nhập sai...",
              maxLines: 2,
            ),
            AppBottomButtons(
              cancelText: "Đóng",
              confirmText: "Xác nhận hủy",
              confirmColor: Colors.redAccent,
              onCancel: () => Navigator.pop(dialogContext),
              onConfirm: () async {
                final refundAmount = double.tryParse(
                  amountController.text.replaceAll(',', ''),
                );
                if (refundAmount == null || refundAmount < 0) {
                  DialogHelper.showWarning(
                    dialogContext,
                    "Số tiền hoàn lại phải là số không âm.",
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                setState(() => isLoading = true);
                final res = await DepositService.updateStatus(
                  widget.depositId,
                  'cancelled',
                  refundAmount: refundAmount,
                  reason: reasonController.text.trim(),
                );

                if (!mounted) return;

                if (res['status'] == 'success') {
                  DialogHelper.showSuccess(
                    context,
                    "Hủy cọc thành công",
                    onTap: () {
                      if (mounted) Navigator.pop(context, true);
                    },
                  );
                } else {
                  setState(() => isLoading = false);
                  DialogHelper.showError(
                    context,
                    res['message'] ?? "Lỗi không xác định",
                  );
                }
              },
            ),
          ],
        ),
      ),
    ).then((_) {
      amountController.dispose();
      reasonController.dispose();
    });
  }

  void _createContract() async {
    if (depositData == null) return;

    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateContractScreen(depositData: depositData),
      ),
    );

    if (!mounted) return;
    if (res == true) {
      Navigator.pop(context, true);
    }
  }

  void _editDeposit() async {
    if (depositData == null) return;

    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateDepositScreen(depositData: depositData),
      ),
    );

    if (!mounted) return;
    if (res == true) {
      setState(() => isLoading = true);
      await _fetchDetail();
    }
  }

  void _handleDelete() {
    DialogHelper.showConfirmDialog(
      context: context,
      title: "XÓA VĨNH VIỄN",
      message:
          "Bạn có chắc chắn muốn xóa vĩnh viễn phiếu cọc này? Hành động này không thể hoàn tác.",
      onConfirm: () async {
        setState(() => isLoading = true);
        final res = await DepositService.deleteDeposit(widget.depositId);
        if (res['status'] == 'success') {
          if (mounted) Navigator.pop(context, true);
        } else {
          setState(() => isLoading = false);
          if (mounted) {
            DialogHelper.showError(
              context,
              res['message'] ?? "Lỗi khi xóa phiếu cọc",
            );
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
          title: "CHI TIẾT CỌC",
          onBack: () => Navigator.pop(context),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (depositData == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: "CHI TIẾT CỌC",
          onBack: () => Navigator.pop(context),
        ),
        body: const Center(child: Text("Lỗi tải dữ liệu")),
      );
    }

    final status = depositData!.status.toLowerCase();
    final isPending = status == 'pending';
    final isCompleted = status == 'completed' || status == 'confirmed';

    String statusText;
    Color statusColor;
    if (status == 'waiting_payment') {
      statusText = "Chờ thanh toán";
      statusColor = Colors.orange;
    } else if (isPending) {
      statusText = "Đã cọc, chờ lập hợp đồng";
      statusColor = Colors.blue;
    } else if (isCompleted) {
      statusText = "Đã thuê";
      statusColor = Colors.green;
    } else if (status == 'expired') {
      statusText = "Hết hạn thanh toán";
      statusColor = Colors.grey;
    } else {
      statusText = "Đã hủy";
      statusColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: CustomAppBar(
        title: "CHI TIẾT PHIẾU CỌC",
        onBack: () => Navigator.pop(context),
        actions: _buildHeaderActions(isPending),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AppSectionCard(
              title: "THÔNG TIN PHIẾU CỌC",
              child: Column(
                children: [
                  DetailRowWidget(
                    icon: Icons.tag,
                    label: "Mã phiếu",
                    value: "#${depositData!.id.toString().padLeft(5, '0')}",
                  ),
                  const DetailDividerWidget(),
                  DetailRowWidget(
                    icon: Icons.meeting_room_outlined,
                    label: "Phòng đã cọc",
                    value: depositData!.roomName ?? "N/A",
                  ),
                  const DetailDividerWidget(),
                  DetailRowWidget(
                    icon: Icons.business_rounded,
                    label: "Nhà trọ",
                    value: depositData!.houseName ?? "N/A",
                  ),
                  const DetailDividerWidget(),
                  DetailRowWidget(
                    icon: Icons.monetization_on_outlined,
                    label: "Số tiền cọc",
                    value: CurrencyHelper.formatVND(depositData!.depositAmount),
                    customValueWidget: Text(
                      CurrencyHelper.formatVND(depositData!.depositAmount),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const DetailDividerWidget(),
                  DetailRowWidget(
                    icon: Icons.info_outline_rounded,
                    label: "Trạng thái",
                    value: statusText,
                    customValueWidget: Text(
                      statusText,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const DetailDividerWidget(),
                  DetailRowWidget(
                    icon: Icons.calendar_today_outlined,
                    label: "Ngày đặt cọc",
                    value: depositData!.depositDate,
                  ),
                ],
              ),
            ),
            _buildDivider(),
            AppSectionCard(
              title: "THÔNG TIN KHÁCH HÀNG",
              child: Column(
                children: [
                  DetailRowWidget(
                    icon: Icons.person_outline_rounded,
                    label: "Tên khách hàng",
                    value: depositData!.customerName,
                  ),
                  const DetailDividerWidget(),
                  DetailRowWidget(
                    icon: Icons.phone_android_rounded,
                    label: "Số điện thoại",
                    value: depositData!.customerPhone,
                  ),
                ],
              ),
            ),
            _buildDivider(),
            AppSectionCard(
              title: "DỰ KIẾN & GHI CHÚ",
              child: Column(
                children: [
                  DetailRowWidget(
                    icon: Icons.event_available_outlined,
                    label: "Dự kiến vào ở",
                    value: depositData!.expectedMoveInDate,
                  ),
                  const DetailDividerWidget(),
                  DetailRowWidget(
                    icon: Icons.note_alt_outlined,
                    label: "Ghi chú",
                    value:
                        depositData!.note == null || depositData!.note!.isEmpty
                        ? 'Không có ghi chú'
                        : depositData!.note!,
                  ),
                ],
              ),
            ),
            _buildDivider(),
            _buildActivityHistory(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: (isPending && userRole != 'tenant')
          ? AppBottomButtons(
              onCancel: _cancelDeposit,
              onConfirm: _createContract,
              cancelText: "Hủy cọc",
              confirmText: "Tạo hợp đồng",
            )
          : null,
    );
  }

  List<Widget>? _buildHeaderActions(bool isPending) {
    if (depositData == null || userRole == 'tenant') return null;

    final canEdit = isPending;
    final canDelete =
        depositData!.status == 'cancelled' && userRole == 'landlord';
    if (!canEdit && !canDelete) return null;

    return [
      IconButton(
        icon: const Icon(Icons.more_horiz, color: Colors.white),
        onPressed: () {
          AppOptionsSheet.show(
            context: context,
            options: [
              if (canEdit)
                AppOptionItem(
                  label: "Sửa phiếu cọc",
                  onTap: _editDeposit,
                ),
              if (canDelete)
                AppOptionItem(
                  label: "Xóa phiếu cọc",
                  isDestructive: true,
                  onTap: _handleDelete,
                ),
            ],
          );
        },
      ),
    ];
  }

  Widget _buildActivityHistory() {
    if (depositData == null || depositData!.logs.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppSectionCard(
      title: "LỊCH SỬ HOẠT ĐỘNG",
      child: Column(
        children: depositData!.logs.map((log) {
          final isCompleted = log.newStatus == 'completed';
          final isCancelled = log.newStatus == 'cancelled';

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(
                      isCompleted
                          ? Icons.check_circle
                          : isCancelled
                          ? Icons.cancel
                          : Icons.history,
                      color: isCompleted
                          ? Colors.green
                          : isCancelled
                          ? Colors.red
                          : Colors.orange,
                      size: 20,
                    ),
                    if (log != depositData!.logs.last)
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
                        isCompleted
                            ? "Đã xác nhận thu cọc / lập hợp đồng"
                            : isCancelled
                            ? "Đã hủy phiếu cọc"
                            : "Cập nhật trạng thái: ${log.newStatus}",
                        style: TextStyle(
                          color: isCompleted
                              ? Colors.green
                              : isCancelled
                              ? Colors.red
                              : Colors.orange,
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
                            "Ghi chú: ${log.reason}",
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

  Widget _buildDivider() {
    return const SizedBox(height: 8);
  }
}
