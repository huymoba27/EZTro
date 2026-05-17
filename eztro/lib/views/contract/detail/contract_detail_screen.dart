import 'package:eztro/core/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/contract_model.dart';
import '../../../services/contract_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../create/create_contract_screen.dart';
import '../providers/contract_notifier.dart';
import '../terminate/terminate_contract_screen.dart';

class ContractDetailScreen extends ConsumerStatefulWidget {
  final ContractModel contract;
  const ContractDetailScreen({super.key, required this.contract});

  @override
  ConsumerState<ContractDetailScreen> createState() =>
      _ContractDetailScreenState();
}

class _ContractDetailScreenState extends ConsumerState<ContractDetailScreen> {
  ContractModel? contractDetail;
  bool isLoading = true;
  bool _hasChanged = false;
  final currencyFormat = NumberFormat("#,###", "vi_VN");
  String userRole = 'landlord';

  @override
  void initState() {
    super.initState();
    _loadFullContract();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() => userRole = user?.role ?? 'landlord');
    }
  }

  Future<void> _loadFullContract() async {
    setState(() => isLoading = true);
    try {
      final data = await ContractService.getContractDetail(
        contractId: widget.contract.id,
      );
      if (mounted) {
        setState(() {
          contractDetail = ContractModel.fromJson(data);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Lỗi tải hợp đồng: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isActive =
        (contractDetail?.status ?? widget.contract.status) == 'active';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: CustomAppBar(
        title: "CHI TIẾT HỢP ĐỒNG",
        onBack: () => Navigator.pop(context, _hasChanged),
        actions: userRole == 'tenant' || !isActive
            ? null
            : [
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => _showOptionsBottomSheet(context),
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : contractDetail == null
              ? const Center(child: Text("Không tìm thấy dữ liệu"))
              : RefreshIndicator(
                  onRefresh: _loadFullContract,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isActive),
                        _buildDivider(),
                        _buildTenantSection(),
                        _buildDivider(),
                        _buildTermsSection(),
                        _buildDivider(),
                        _buildServicesSection(),
                        _buildDivider(),
                        _buildActivityHistory(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActivityHistory() {
    final logs = contractDetail?.logs ?? [];
    if (logs.isEmpty) return const SizedBox.shrink();

    return AppSectionCard(
      title: "NHẬT KÝ HỢP ĐỒNG",
      child: Column(
        children: logs.map((log) {
          bool isTerminate = log.action == 'terminate';
          bool isUpdate = log.action == 'update';

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(
                      isTerminate
                          ? Icons.account_balance_wallet
                          : log.action == 'create'
                          ? Icons.assignment_turned_in
                          : log.action == 'cancel'
                          ? Icons.cancel_outlined
                          : isUpdate
                          ? Icons.published_with_changes
                          : Icons.history,
                      color: isTerminate
                          ? Colors.orange
                          : log.action == 'create'
                          ? Colors.green
                          : log.action == 'cancel'
                          ? Colors.red
                          : isUpdate
                          ? Colors.blue
                          : Colors.grey,
                      size: 20,
                    ),
                    if (log != logs.last)
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
                        log.reason ?? "Cập nhật hợp đồng",
                        style: TextStyle(
                          color: isTerminate ? Colors.red : Colors.black87,
                          fontSize: 12,
                          fontWeight: isUpdate
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      if (log.refundAmount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Hoàn cọc: ${currencyFormat.format(log.refundAmount)}đ",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
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

  Widget _buildHeader(bool isActive) {
    final contract = contractDetail!;
    return AppSectionCard(
      title: "THÔNG TIN CHUNG",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailRowWidget(
            icon: Icons.meeting_room_outlined,
            label: "Phòng thuê",
            value: contract.roomName,
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.home_work_outlined,
            label: "Nhà trọ",
            value: contract.houseName ?? "N/A",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.info_outline,
            label: "Trạng thái",
            value: "",
            customValueWidget: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isActive ? "CÒN HẠN" : "ĐÃ KẾT THÚC",
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantSection() {
    final contract = contractDetail!;
    return AppSectionCard(
      title: "KHÁCH THUÊ ĐẠI DIỆN",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailRowWidget(
            icon: Icons.person_outline,
            label: "Họ tên",
            value: contract.tenantName ?? "N/A",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.phone_android_outlined,
            label: "Số điện thoại",
            value: contract.tenantPhone ?? "N/A",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.badge_outlined,
            label: "Số CCCD",
            value: contract.idCard ?? "Chưa cập nhật",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.location_on_outlined,
            label: "Thường trú",
            value: contract.address ?? "Chưa cập nhật",
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection() {
    final contract = contractDetail!;
    return AppSectionCard(
      title: "ĐIỀU KHOẢN HỢP ĐỒNG",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailRowWidget(
            icon: Icons.calendar_today_outlined,
            label: "Ngày vào ở",
            value: contract.startDate,
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.event_available_outlined,
            label: "Ngày hết hạn",
            value: contract.endDate,
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.payments_outlined,
            label: "Tiền thuê",
            value: "${currencyFormat.format(contract.rentPrice)} đ/tháng",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.security_outlined,
            label: "Tiền đặt cọc",
            value: "${currencyFormat.format(contract.depositAmount)} đ",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.today_outlined,
            label: "Ngày thu tiền",
            value: "Ngày ${contract.paymentDay} hàng tháng",
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    final contract = contractDetail!;
    final services = contract.services ?? [];
    return AppSectionCard(
      title: "DỊCH VỤ & CHỈ SỐ",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailRowWidget(
            icon: Icons.bolt,
            label: "Điện đầu kỳ",
            value: "${contract.startElectric} kWh",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.water_drop_outlined,
            label: "Nước đầu kỳ",
            value: "${contract.startWater} m³",
          ),
          if (services.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 20, bottom: 8),
              child: Text(
                "Dịch vụ đăng ký:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ),
            ...services.map(
              (s) => DetailRowWidget(
                icon: Icons.check_circle_outline,
                label: s.serviceName,
                value: "${currencyFormat.format(s.price)}đ/${s.unit}",
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() => const SizedBox(height: 8);

  Future<void> _deleteMistakenContract() async {
    final contract = contractDetail ?? widget.contract;

    DialogHelper.showConfirmDialog(
      context: context,
      title: "HỦY HỢP ĐỒNG",
      message:
          "Lưu ý: Chỉ dùng khi bạn nhập nhầm thông tin hoặc tạo sai. Nếu khách đã dọn đi thực tế, bạn phải dùng chức năng Thanh lý để chốt điện nước và tiền cọc.",
      onConfirm: () async {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );

        try {
          final res = await ref
              .read(contractNotifierProvider.notifier)
              .deleteContract(roomId: contract.roomId, contractId: contract.id);

          if (mounted) Navigator.pop(context);

          if (res['status'] == 'success') {
            _hasChanged = true;
            if (mounted) {
              DialogHelper.showSuccess(
                context,
                res['message'] ?? "Đã hủy hợp đồng nhập nhầm",
                onTap: () {
                  if (mounted) Navigator.pop(context, true);
                },
              );
            }
          } else if (mounted) {
            DialogHelper.showError(
              context,
              res['message'] ??
                  "Không thể hủy hợp đồng. Vui lòng kiểm tra lại dữ liệu.",
            );
          }
        } catch (e) {
          if (mounted) Navigator.pop(context);
          if (mounted) DialogHelper.showError(context, "Loi ket noi API: $e");
        }
      },
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    AppOptionsSheet.show(
      context: context,
      title: "TÙY CHỌN HỢP ĐỒNG",
      options: [
        AppOptionItem(
          label: "Cập nhật hợp đồng",
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CreateContractScreen(contractData: contractDetail),
              ),
            );
            if (result == true) {
              _hasChanged = true;
              _loadFullContract();
            }
          },
        ),
        AppOptionItem(
          label: "Thanh lý tất toán",
          isDestructive: true,
          onTap: () async {
            // Show loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );

            try {
              final res = await ContractService.getSettlementPreview(
                widget.contract.id,
              );
              if (mounted) Navigator.pop(context); // Hide loading

              if (res['status'] == 'success') {
                bool hasInvoice = res['data']['has_invoice_this_month'] == true;
                if (!hasInvoice) {
                  if (mounted) {
                    DialogHelper.showError(
                      context,
                      "Chưa có hóa đơn tháng ${res['data']['current_month']}. Vui lòng lập hóa đơn để chốt chỉ số điện nước trước khi thực hiện thanh lý.",
                    );
                  }
                  return;
                }

                if (mounted) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TerminateContractScreen(
                        contractId: widget.contract.id,
                        initialData: res['data'],
                      ),
                    ),
                  );
                  if (result == true) {
                    _hasChanged = true;
                    _loadFullContract();
                    if (mounted) {
                      Navigator.pop(
                        context,
                        true,
                      ); // Pop the bottom sheet and pass true back to previous screen
                      DialogHelper.showSuccess(
                        context,
                        "Thanh lý hợp đồng thành công!",
                      );
                    }
                  }
                }
              } else {
                if (mounted) {
                  DialogHelper.showError(
                    context,
                    res['message'] ?? "Lỗi tải dữ liệu",
                  );
                }
              }
            } catch (e) {
              if (mounted) Navigator.pop(context); // Hide loading
              if (mounted) DialogHelper.showError(context, "Lỗi kết nối");
            }
          },
        ),
        AppOptionItem(
          label: "Hủy hợp đồng",
          isDestructive: true,
          onTap: _deleteMistakenContract,
        ),
      ],
    );
  }
}
