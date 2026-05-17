import 'package:flutter/material.dart';
import '../../../../models/house_model.dart';
import '../../../../services/api_constants.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../../core/utils/amenity_helper.dart';

// =============================================================================
// 1. BANNER/HEADER CHI TIẾT (HouseDetailHeader)
// =============================================================================
class HouseDetailHeader extends StatelessWidget {
  final HouseModel house;
  const HouseDetailHeader({super.key, required this.house});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: house.image.isNotEmpty
          ? Image.network(
              "${ApiConstants.serverUrl}/uploads/houses/${house.image}",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.home_work_outlined,
                color: Colors.black12,
                size: 60,
              ),
            )
          : const Icon(
              Icons.home_work_outlined,
              color: Colors.black12,
              size: 60,
            ),
    );
  }
}

// =============================================================================
// 2. THÔNG TIN CƠ BẢN & CHI TIẾT (HouseInfoSection)
// =============================================================================
class HouseInfoSection extends StatelessWidget {
  final HouseModel house;
  const HouseInfoSection({super.key, required this.house});

  @override
  Widget build(BuildContext context) {
    final addressText = "${house.addressDetail ?? ''}, ${house.ward}, ${house.city}"
        .replaceAll(RegExp(r'^, '), '');

    return Column(
      children: [
        // Tên & Địa chỉ
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                house.houseName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.black45),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      addressText,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Thông tin chi tiết
        AppSectionCard(
          title: "THÔNG TIN CHI TIẾT",
          child: Column(
            children: [
              DetailRowWidget(
                icon: Icons.layers_outlined,
                label: "Số tầng",
                value: "${house.floors ?? 1} tầng",
              ),
              const Divider(height: 1, thickness: 0.5),
              DetailRowWidget(
                icon: Icons.meeting_room_outlined,
                label: "Tổng số phòng",
                value: "${house.totalRooms} phòng",
              ),
              const Divider(height: 1, thickness: 0.5),
              DetailRowWidget(
                icon: Icons.people_outline,
                label: "Khách đang thuê",
                value: "${house.totalTenants} người",
              ),
              const Divider(height: 1, thickness: 0.5),
              DetailRowWidget(
                icon: Icons.square_foot_outlined,
                label: "Diện tích khu đất",
                value: "${house.totalArea?.toStringAsFixed(house.totalArea?.truncateToDouble() == house.totalArea ? 0 : 1) ?? 0} m²",
              ),
              const Divider(height: 1, thickness: 0.5),
              DetailRowWidget(
                icon: Icons.info_outline,
                label: "Trạng thái",
                value: house.status == "active" ? "Đang hoạt động" : "Ngừng kinh doanh",
              ),
              const Divider(height: 1, thickness: 0.5),
              DetailRowWidget(
                icon: Icons.person_pin_outlined,
                label: "Chủ sở hữu",
                value: house.ownerName ?? "Chưa cập nhật",
              ),
              if (house.ownerPhone != null && house.ownerPhone!.isNotEmpty) ...[
                const Divider(height: 1, thickness: 0.5),
                DetailRowWidget(
                  icon: Icons.phone_android_outlined,
                  label: "SĐT Chủ sở hữu",
                  value: house.ownerPhone!,
                ),
              ],
              if (house.managerName != null && house.managerName!.isNotEmpty) ...[
                const Divider(height: 1, thickness: 0.5),
                DetailRowWidget(
                  icon: Icons.person_outline,
                  label: "Người quản lý",
                  value: house.managerName!,
                ),
              ],
              if (house.managerPhone != null && house.managerPhone!.isNotEmpty) ...[
                const Divider(height: 1, thickness: 0.5),
                DetailRowWidget(
                  icon: Icons.phone_outlined,
                  label: "SĐT Người quản lý",
                  value: house.managerPhone!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 3. SECTION TIỆN ÍCH (HouseAmenitiesSection)
// =============================================================================
class HouseAmenitiesSection extends StatelessWidget {
  final HouseModel house;
  const HouseAmenitiesSection({super.key, required this.house});

  @override
  Widget build(BuildContext context) {
    final amenities = house.amenities ?? [];

    return AppSectionCard(
      title: "TIỆN ÍCH",
      child: amenities.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "Chưa cập nhật tiện ích cho khu trọ này",
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: amenities.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 3.5,
              ),
              itemBuilder: (context, index) =>
                  HouseAmenityTile(name: amenities[index].name),
            ),
    );
  }
}

// =============================================================================
// 4. TILE TIỆN ÍCH LẺ (HouseAmenityTile)
// =============================================================================
class HouseAmenityTile extends StatelessWidget {
  final String name;

  const HouseAmenityTile({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final IconData iconData = AmenityHelper.getIcon(name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(iconData, color: Colors.black87, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
