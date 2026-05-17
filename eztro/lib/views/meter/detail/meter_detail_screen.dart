import 'package:flutter/material.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../services/api_constants.dart';
import '../../../core/utils/dialog_helper.dart';

class MeterDetailScreen extends StatelessWidget {
  final dynamic room;
  final int month;
  final int year;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String userRole;

  const MeterDetailScreen({
    super.key,
    required this.room,
    required this.month,
    required this.year,
    required this.onEdit,
    required this.onDelete,
    this.userRole = 'landlord',
  });

  @override
  Widget build(BuildContext context) {
    // Tính toán an toàn
    int newE = int.tryParse(room['new_electric']?.toString() ?? '0') ?? 0;
    int oldE = int.tryParse(room['old_electric']?.toString() ?? '0') ?? 0;
    int newW = int.tryParse(room['new_water']?.toString() ?? '0') ?? 0;
    int oldW = int.tryParse(room['old_water']?.toString() ?? '0') ?? 0;

    bool hasInvoice = room['invoice_id'] != null && room['invoice_id'].toString() != '0';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: CustomAppBar(
        title: "CHI TIẾT ĐIỆN NƯỚC",
        onBack: () => Navigator.pop(context),
        actions: userRole == 'tenant'
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white, size: 28),
                  onPressed: () {
                    AppOptionsSheet.show(
                      context: context,
                      title: "TÙY CHỌN",
                      options: [
                        AppOptionItem(
                          label: "Sửa chỉ số",
                          onTap: () {
                            if (hasInvoice) {
                              DialogHelper.showError(
                                context,
                                "Số điện nước này đã được lập hóa đơn. Vui lòng xóa hóa đơn trước khi sửa.",
                              );
                              return;
                            }
                            onEdit();
                          },
                        ),
                        AppOptionItem(
                          label: "Xóa bản ghi",
                          isDestructive: true,
                          onTap: () {
                            if (hasInvoice) {
                              DialogHelper.showError(
                                context,
                                "Số điện nước này đã được lập hóa đơn. Vui lòng xóa hóa đơn trước khi xóa.",
                              );
                              return;
                            }
                            onDelete();
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. THÔNG TIN CHUNG
            AppSectionCard(
              title: "THÔNG TIN CHUNG",
              child: Column(
                children: [
                  DetailRowWidget(
                    icon: Icons.business_rounded,
                    label: "Nhà trọ",
                    value: room['house_name'] ?? "---",
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  DetailRowWidget(
                    icon: Icons.meeting_room_outlined,
                    label: "Phòng",
                    value: room['room_name'] ?? "---",
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  DetailRowWidget(
                    icon: Icons.calendar_today_outlined,
                    label: "Kỳ hóa đơn",
                    value: "Tháng $month/$year",
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  DetailRowWidget(
                    icon: Icons.person_outline,
                    label: "Người chốt",
                    value:
                        room['staff_name'] ??
                        room['recorded_by_name'] ??
                        "Hệ thống",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 2. CHỈ SỐ ĐIỆN
            AppSectionCard(
              title: "CHỈ SỐ ĐIỆN",
              child: Column(
                children: [
                  DetailRowWidget(
                    icon: Icons.bolt,
                    label: "Số mới",
                    value: "$newE kWh",
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  DetailRowWidget(
                    icon: Icons.history,
                    label: "Số cũ",
                    value: "$oldE kWh",
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  DetailRowWidget(
                    icon: Icons.speed,
                    label: "Tiêu thụ",
                    value: "${newE - oldE} kWh",
                    customValueWidget: Text(
                      "${newE - oldE} kWh",
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 3. CHỈ SỐ NƯỚC
            AppSectionCard(
              title: "CHỈ SỐ NƯỚC",
              child: Column(
                children: [
                  DetailRowWidget(
                    icon: Icons.water_drop_outlined,
                    label: "Số mới",
                    value: "$newW m³",
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  DetailRowWidget(
                    icon: Icons.history,
                    label: "Số cũ",
                    value: "$oldW m³",
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  DetailRowWidget(
                    icon: Icons.opacity,
                    label: "Tiêu thụ",
                    value: "${newW - oldW} m³",
                    customValueWidget: Text(
                      "${newW - oldW} m³",
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 4. HÌNH ẢNH MINH CHỨNG (Để ở dưới cùng theo yêu cầu)
            AppSectionCard(
              title: "HÌNH ẢNH MINH CHỨNG",
              child: Row(
                children: [
                  _buildImageContainer("Ảnh Điện", room['electric_image']),
                  const SizedBox(width: 12),
                  _buildImageContainer("Ảnh Nước", room['water_image']),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContainer(String label, String? imageName) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (imageName != null && imageName.isNotEmpty)
                    ? Image.network(
                        "${ApiConstants.serverUrl}/uploads/meters/$imageName",
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.broken_image,
                              size: 30,
                              color: Colors.grey,
                            ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.black12,
                          size: 40,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
