import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../services/tenant_service.dart';
import '../../../core/constants/app_colors.dart';
import 'package:eztro/core/widgets/widgets.dart';
import 'edit_tenant_screen.dart';
import '../../../models/tenant_model.dart';
import '../providers/tenant_notifier.dart';

class TenantDetailScreen extends ConsumerStatefulWidget {
  final TenantModel tenant;

  const TenantDetailScreen({super.key, required this.tenant});

  @override
  ConsumerState<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends ConsumerState<TenantDetailScreen> {
  late TenantModel currentTenant;
  bool _isLoading = false;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    currentTenant = widget.tenant;
    // Tải lại dữ liệu đầy đủ để lấy Nhật ký (Logs)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTenantData();
    });
  }

  Future<void> _refreshTenantData() async {
    setState(() => _isLoading = true);
    try {
      final newData = await TenantService.getTenantDetail(
        tenantId: currentTenant.id,
      );
      if (newData != null) {
        setState(() {
          currentTenant = TenantModel.fromJson(newData);
          _hasChanged = true;
        });
      }
    } catch (e) {
      debugPrint("Lỗi cập nhật data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleDeleteTenant() {
    DialogHelper.showConfirmDialog(
      context: context,
      title: "XÁC NHẬN XÓA",
      message: "Bạn có chắc chắn muốn xóa khách thuê này khỏi hệ thống?",
      onConfirm: () async {
        setState(() => _isLoading = true);
        final res = await ref
            .read(tenantNotifierProvider.notifier)
            .deleteTenant(currentTenant.id);
        if (mounted) setState(() => _isLoading = false);

        if (res['status'] == 'success') {
          if (!mounted) return;
          DialogHelper.showSuccess(
            context,
            "Đã xóa khách thuê thành công",
            onTap: () => Navigator.pop(context, true),
          );
        } else {
          if (mounted) {
            DialogHelper.showError(
              context,
              res['message'] ?? "Không thể xóa khách thuê",
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanged);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: CustomAppBar(
          title: 'CHI TIẾT KHÁCH THUÊ',
          onBack: () => Navigator.pop(context, _hasChanged),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.white, size: 28),
              onPressed: () => _showOptionsBottomSheet(context),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderSection(),
                  _buildDivider(),
                  _buildInfoSection(),
                  const SizedBox(height: 8),
                  _buildActivityHistory(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    AppOptionsSheet.show(
      context: context,
      options: [
        AppOptionItem(
          label: "Cập nhật thông tin",
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditTenantScreen(tenant: currentTenant.toJson()),
              ),
            );
            if (result == true) {
              _refreshTenantData();
            }
          },
        ),
        AppOptionItem(
          label: "Xóa khách thuê",
          isDestructive: true,
          onTap: _handleDeleteTenant,
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                currentTenant.tenantName.isNotEmpty
                    ? currentTenant.tenantName[0].toUpperCase()
                    : "U",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTenant.tenantName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  currentTenant.phone ?? "N/A",
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.phone_in_talk_rounded,
              color: AppColors.primary,
              size: 28,
            ),
            onPressed: () => launchUrl(Uri.parse("tel:${currentTenant.phone}")),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return AppSectionCard(
      title: "THÔNG TIN CHI TIẾT",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailRowWidget(
            icon: Icons.business_rounded,
            label: "Nhà",
            value: currentTenant.houseName ?? "N/A",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.meeting_room_rounded,
            label: "Phòng",
            value: currentTenant.roomName ?? "N/A",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.cake_outlined,
            label: "Ngày sinh",
            value: currentTenant.birthday ?? "N/A",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.wc_rounded,
            label: "Giới tính",
            value: currentTenant.gender ?? "N/A",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.badge_outlined,
            label: "CMND/CCCD",
            value: currentTenant.idCard ?? "N/A",
          ),
          const DetailDividerWidget(),
          DetailRowWidget(
            icon: Icons.mail_outline_rounded,
            label: "Email",
            value: currentTenant.email ?? "N/A",
          ),
        ],
      ),
    );
  }

  Widget _buildActivityHistory() {
    if (currentTenant.logs.isEmpty) return const SizedBox.shrink();

    return AppSectionCard(
      title: "Lịch sử hoạt động",
      child: Column(
        children: currentTenant.logs.map((log) {
          IconData icon;
          Color color;
          String actionText;

          switch (log.action) {
            case 'create':
              icon = Icons.person_add_alt_1;
              color = Colors.green;
              actionText = "Thêm mới khách thuê";
              break;
            case 'update':
              icon = Icons.edit_note_rounded;
              color = Colors.blue;
              actionText = "Cập nhật thông tin";
              break;
            case 'deactivate':
              icon = Icons.person_off_rounded;
              color = Colors.red;
              actionText = "Thanh lý / Rời phòng";
              break;
            default:
              icon = Icons.history;
              color = Colors.grey;
              actionText = log.action;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(icon, color: color, size: 22),
                    if (log != currentTenant.logs.last)
                      Container(
                        width: 1.5,
                        height: 35,
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
                        actionText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${log.userName} (${log.userRole == 'landlord' ? 'Chủ trọ' : log.userRole == 'manager' ? 'Quản lý' : 'Hệ thống'})",
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      if (log.reason != null && log.reason!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            log.reason!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        log.createdAt,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
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
}

Widget _buildDetailDivider() =>
    Divider(height: 1, thickness: 0.8, color: Colors.black.withOpacity(0.08));

Widget _buildDivider() {
  return const SizedBox(height: 8);
}
