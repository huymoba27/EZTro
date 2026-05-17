import 'package:flutter/material.dart';
import '../../../models/vehicle_model.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../services/api_constants.dart';

class VehicleDetailScreen extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VehicleDetailScreen({
    super.key,
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String? rawImage = vehicle.vehicleImage;
    String? imageUrl;
    if (rawImage != null && rawImage.isNotEmpty) {
      imageUrl = rawImage.startsWith('http')
          ? rawImage
          : "${ApiConstants.baseImageUrl}/uploads/vehicles/$rawImage";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: CustomAppBar(
        title: "CHI TIẾT PHƯƠNG TIỆN",
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. THÔNG TIN PHƯƠNG TIỆN
            AppSectionCard(
              title: "THÔNG TIN PHƯƠNG TIỆN",
              child: Column(
                children: [
                  DetailRowWidget(
                    icon: Icons.motorcycle,
                    label: "Loại xe",
                    value: vehicle.vehicleType.toUpperCase(),
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  DetailRowWidget(
                    icon: Icons.pin_outlined,
                    label: "Biển số xe",
                    value: vehicle.plateNumber.toUpperCase(),
                    customValueWidget: Text(
                      vehicle.plateNumber.toUpperCase(),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  DetailRowWidget(
                    icon: Icons.calendar_today_outlined,
                    label: "Ngày đăng ký",
                    value: vehicle.createdAt?.split(' ')[0] ?? "---",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 2. THÔNG TIN CHỦ XE & VỊ TRÍ
            AppSectionCard(
              title: "CHỦ XE & VỊ TRÍ",
              child: Column(
                children: [
                  DetailRowWidget(
                    icon: Icons.person_outline,
                    label: "Chủ xe",
                    value: vehicle.tenantName,
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  DetailRowWidget(
                    icon: Icons.business_rounded,
                    label: "Nhà trọ",
                    value: vehicle.houseName,
                  ),
                  const Divider(height: 1, thickness: 0.5),
                  DetailRowWidget(
                    icon: Icons.meeting_room_outlined,
                    label: "Phòng",
                    value: vehicle.roomName,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 3. HÌNH ẢNH XE (Để ở dưới cùng theo yêu cầu)
            AppSectionCard(
              title: "HÌNH ẢNH XE",
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (imageUrl != null)
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                          )
                        : const Icon(
                            Icons.motorcycle,
                            size: 60,
                            color: Colors.grey,
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomButtons(
        onCancel: onDelete,
        onConfirm: onEdit,
        cancelText: "XÓA",
        confirmText: "SỬA",
      ),
    );
  }
}
