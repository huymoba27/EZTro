import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/incident_model.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../services/api_constants.dart';
import '../detail/incident_detail_screen.dart';
import '../../../core/utils/dialog_helper.dart';
import '../providers/incident_notifier.dart';

class IncidentCard extends ConsumerWidget {
  final IncidentModel incident;

  const IncidentCard({super.key, required this.incident});

  void _handleUpdateStatus(
    BuildContext context,
    WidgetRef ref,
    IncidentModel item,
  ) {
    if (item.status == 'resolved') return;

    final String nextStatus = item.status == 'pending'
        ? 'processing'
        : 'resolved';

    if (nextStatus == 'resolved') {
      Navigator.pop(context); // Close detail modal
      _showCostInputDialog(context, ref, item);
    } else {
      Navigator.pop(context); // Close detail modal
      ref
          .read(incidentNotifierProvider.notifier)
          .updateStatus(incident: item, status: nextStatus);
    }
  }

  void _showCostInputDialog(
    BuildContext context,
    WidgetRef ref,
    IncidentModel item,
  ) {
    final TextEditingController costController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Xác nhận hoàn tất",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Vui lòng nhập chi phí sửa chữa để ghi nhận vào hệ thống thu chi:",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: costController,
              label: "Số tiền (VNĐ)",
              hint: "0",
              keyboardType: TextInputType.number,
            ),
            AppBottomButtons(
              cancelText: "Hủy",
              confirmText: "Hoàn tất",
              onCancel: () => Navigator.pop(context),
              onConfirm: () async {
                final cost = double.tryParse(costController.text) ?? 0;
                Navigator.pop(context);
                final res = await ref
                    .read(incidentNotifierProvider.notifier)
                    .updateStatus(
                      incident: item,
                      status: 'resolved',
                      repairCost: cost,
                    );
                if (!context.mounted) return;
                if (res['status'] == 'success') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Đã giải quyết sự cố và tạo phiếu chi!"),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    ).then((_) => costController.dispose());
  }

  void _handleDelete(BuildContext context, WidgetRef ref, IncidentModel item) {
    Navigator.pop(context); // Close detail modal
    DialogHelper.showConfirmDialog(
      context: context,
      title: "Xóa sự cố",
      message: "Bạn có chắc chắn muốn xóa báo cáo sự cố này?",
      onConfirm: () async {
        final res = await ref
            .read(incidentNotifierProvider.notifier)
            .deleteIncident(item.id!);
        if (!context.mounted) return;
        if (res['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã xóa sự cố thành công")),
          );
        } else {
          DialogHelper.showError(context, res['message'] ?? "Lỗi xóa sự cố");
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstImage = incident.images.isNotEmpty ? incident.images[0] : "";

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IncidentDetailScreen(
                      incident: incident,
                      onUpdateStatus: () =>
                          _handleUpdateStatus(context, ref, incident),
                      onDelete: () => _handleDelete(context, ref, incident),
                    ),
                  ),
                );
              },
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Section (Style like RoomCard)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: firstImage.isNotEmpty
                              ? Image.network(
                                  "${ApiConstants.serverUrl}/uploads/incidents/$firstImage",
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: const Color(0xFFF8F9FA),
                                        child: const Icon(
                                          Icons.report_problem_outlined,
                                          color: Colors.black12,
                                          size: 30,
                                        ),
                                      ),
                                )
                              : Container(
                                  color: const Color(0xFFF8F9FA),
                                  child: const Icon(
                                    Icons.report_problem_outlined,
                                    color: Colors.black12,
                                    size: 30,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // Info Section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    incident.title.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: Color(0xFF263238),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                AppStatusBadge(status: incident.status),
                              ],
                            ),

                            // Sender (Người gửi)
                            CardInfoRow(
                              icon: Icons.person_outline_rounded,
                              text: "Gửi bởi: ${incident.tenantName ?? 'N/A'}",
                            ),

                            const SizedBox(height: 4),

                            // Room
                            CardInfoRow(
                              icon: Icons.meeting_room_outlined,
                              text: "Phòng: ${incident.roomName}",
                            ),

                            const SizedBox(height: 4),

                            // Last line: House & Time
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: CardInfoRow(
                                    icon: Icons.home_outlined,
                                    text: "Nhà: ${incident.houseName ?? 'N/A'}",
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'HH:mm dd/MM/yy',
                                  ).format(incident.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black38,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.8,
          indent: 16,
          endIndent: 16,
          color: Colors.black.withValues(alpha: 0.22),
        ),
      ],
    );
  }
}
