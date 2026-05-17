import 'package:flutter/material.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../models/service_model.dart';
import '../../../../core/constants/app_colors.dart';

class ContractServicesWidget extends StatelessWidget {
  final List<ServiceModel> houseServices;
  final List<int> selectedServiceIds;
  final Function(int, bool) onServiceToggled;
  final bool hasVehicles;

  const ContractServicesWidget({
    super.key,
    required this.houseServices,
    required this.selectedServiceIds,
    required this.onServiceToggled,
    this.hasVehicles = false,
  });

  bool _isEssential(String name) {
    final n = name.toLowerCase();
    return n.contains("điện") || n.contains("nước");
  }

  bool _isVehicle(String name) {
    final n = name.toLowerCase();
    return n.contains("xe");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (houseServices.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisExtent: 65, // Tăng nhẹ để đủ chỗ cho subtitle dài
            ),
            itemCount: houseServices.length,
            itemBuilder: (context, index) {
              final svc = houseServices[index];
              final bool isEssential = _isEssential(svc.serviceName);
              final bool isVehicleSvc = _isVehicle(svc.serviceName);
              
              // Tự động tích nếu là Điện/Nước hoặc nếu đang có xe
              bool isSelected = selectedServiceIds.contains(svc.id);
              if (isEssential) isSelected = true;

              // Khóa nếu là Điện/Nước hoặc nếu là Xe và đang có xe đăng ký
              final bool isLocked = isEssential || (isVehicleSvc && hasVehicles);

              Widget tile = CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: Text(
                  svc.serviceName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${CurrencyHelper.formatVND(svc.price)}/${svc.unit}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (isVehicleSvc && hasVehicles)
                      const Text(
                        "Phòng đang có xe, cần xóa xe trước khi bỏ dịch vụ",
                        style: TextStyle(fontSize: 10, color: Colors.redAccent, fontStyle: FontStyle.italic),
                      ),
                    if (isEssential)
                      const Text(
                        "Dịch vụ bắt buộc",
                        style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
                value: isSelected,
                onChanged: (val) => onServiceToggled(svc.id, val ?? false),
              );

              if (isLocked) {
                return IgnorePointer(
                  ignoring: true,
                  child: tile,
                );
              }
              return tile;
            },
          ),
          const SizedBox(height: 8),
        ] else ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                "Nhà này chưa có cấu hình dịch vụ",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
