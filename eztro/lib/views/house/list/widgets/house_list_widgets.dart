import 'package:flutter/material.dart';
import '../../../../models/house_model.dart';
import '../../../../services/api_constants.dart';
import 'package:eztro/core/widgets/widgets.dart';

// =============================================================================
// 1. CARD HIỂN THỊ NHÀ TRỌ (HouseCard)
// =============================================================================
class HouseCard extends StatelessWidget {
  final HouseModel house;
  final VoidCallback onTap;

  const HouseCard({super.key, required this.house, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final addressText = [
      if (house.addressDetail != null && house.addressDetail!.isNotEmpty)
        house.addressDetail,
      if (house.ward.isNotEmpty) house.ward,
      if (house.city.isNotEmpty) house.city,
    ].join(', ');
    final emptyRooms = house.totalEmptyRooms;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ảnh bên trái
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: house.image.isNotEmpty
                        ? Image.network(
                            "${ApiConstants.serverUrl}/uploads/houses/${house.image}",
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: const Color(0xFFF8F9FA),
                                  child: const Icon(
                                    Icons.home_work_outlined,
                                    color: Colors.black12,
                                    size: 30,
                                  ),
                                ),
                          )
                        : Container(
                            color: const Color(0xFFF8F9FA),
                            child: const Icon(
                              Icons.home_work_outlined,
                              color: Colors.black12,
                              size: 30,
                            ),
                          ),
                  ),
                ),
              ),

              // Thông tin bên phải
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        house.houseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF263238),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      CardInfoRow(
                        icon: Icons.location_on_outlined,
                        text: addressText,
                      ),
                      const SizedBox(height: 6),
                        CardInfoRow(
                          icon: Icons.aspect_ratio,
                          text:
                              "${(house.totalArea ?? 0).toString().replaceAll(RegExp(r'\.0$'), '')}m² • ${house.floors ?? 1} tầng",
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (emptyRooms > 0 ? Colors.green : Colors.red)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          emptyRooms > 0
                              ? "TRỐNG $emptyRooms/${house.totalRooms} PHÒNG"
                              : "HẾT PHÒNG",
                          style: TextStyle(
                            fontSize: 9,
                            color: emptyRooms > 0
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
