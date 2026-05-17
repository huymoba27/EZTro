import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/incident_model.dart';
import '../../../core/utils/format_helper.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../services/api_constants.dart';
import '../../../services/incident_service.dart';
import '../../auth/providers/auth_provider.dart';

class IncidentDetailScreen extends ConsumerStatefulWidget {
  final IncidentModel? incident;
  final int? incidentId;
  final VoidCallback? onUpdateStatus;
  final VoidCallback? onDelete;

  const IncidentDetailScreen({
    super.key,
    this.incident,
    this.incidentId,
    this.onUpdateStatus,
    this.onDelete,
  });

  @override
  ConsumerState<IncidentDetailScreen> createState() =>
      _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends ConsumerState<IncidentDetailScreen> {
  IncidentModel? currentIncident;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.incident != null) {
      currentIncident = widget.incident;
    } else if (widget.incidentId != null) {
      _fetchIncident();
    }
  }

  Future<void> _fetchIncident() async {
    setState(() => isLoading = true);
    final data = await IncidentService.getIncidentDetail(widget.incidentId!);
    if (mounted) {
      setState(() {
        currentIncident = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final bool isTenant = user?.role == 'tenant';

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (currentIncident == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: "CHI TIẾT SỰ CỐ",
          onBack: () => Navigator.pop(context),
        ),
        body: const Center(child: Text("Không tìm thấy thông tin sự cố")),
      );
    }

    final incident = currentIncident!;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: CustomAppBar(
        title: "CHI TIẾT SỰ CỐ",
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. TRẠNG THÁI & THÔNG TIN CHUNG
            AppSectionCard(
              title: "TRẠNG THÁI & THÔNG TIN CHUNG",
              child: Column(
                children: [
                  DetailRowWidget(
                    icon: Icons.title,
                    label: "Sự cố",
                    value: incident.title.toUpperCase(),
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  DetailRowWidget(
                    icon: Icons.info_outline,
                    label: "Trạng thái",
                    value: _getStatusLabel(incident.status),
                    customValueWidget: Text(
                      _getStatusLabel(incident.status),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: _getStatusColor(incident.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  DetailRowWidget(
                    icon: Icons.calendar_today_outlined,
                    label: "Ngày gửi",
                    value: DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(incident.createdAt),
                  ),
                  if (incident.status == 'resolved') ...[
                    const Divider(height: 1, thickness: 0.5),
                    DetailRowWidget(
                      icon: Icons.payments_outlined,
                      label: "Phí sửa chữa",
                      value: CurrencyHelper.formatVND(incident.repairCost),
                      customValueWidget: Text(
                        CurrencyHelper.formatVND(incident.repairCost),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 2. VỊ TRÍ & NGƯỜI BÁO
            AppSectionCard(
              title: "VỊ TRÍ & NGƯỜI BÁO",
              child: Column(
                children: [
                  DetailRowWidget(
                    icon: Icons.person_outline,
                    label: "Người báo",
                    value: incident.tenantName ?? "N/A",
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  DetailRowWidget(
                    icon: Icons.business_rounded,
                    label: "Nhà trọ",
                    value: incident.houseName ?? "N/A",
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  DetailRowWidget(
                    icon: Icons.meeting_room_outlined,
                    label: "Phòng",
                    value: "Phòng ${incident.roomName}",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 3. NỘI DUNG CHI TIẾT
            AppSectionCard(
              title: "NỘI DUNG CHI TIẾT",
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  incident.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 4. HÌNH ẢNH MINH CHỨNG
            if (incident.images.isNotEmpty)
              AppSectionCard(
                title: "HÌNH ẢNH MINH CHỨNG",
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: incident.images.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final img = incident.images[index];
                    final url = img.startsWith('http')
                        ? img
                        : "${ApiConstants.serverUrl}/uploads/incidents/$img";
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: (!isTenant && incident.status != 'resolved')
          ? AppBottomButtons(
              onCancel: widget.onDelete ?? () {},
              onConfirm: widget.onUpdateStatus ?? () {},
              cancelText: "XÓA",
              confirmText: incident.status == 'pending'
                  ? "TIẾP NHẬN"
                  : "HOÀN TẤT",
            )
          : AppBottomButtons(
              onConfirm: widget.onDelete ?? () {},
              confirmText: "XÓA",
              confirmColor: Colors.red[500],
              showCancel: false,
            ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return "MỚI GỬI";
      case 'processing':
        return "ĐANG XỬ LÝ";
      case 'resolved':
        return "ĐÃ XONG";
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
