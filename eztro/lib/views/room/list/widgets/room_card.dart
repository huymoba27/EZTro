import 'package:flutter/material.dart';
import 'package:eztro/models/room_model.dart';
import 'package:eztro/services/api_constants.dart';
import 'package:eztro/core/widgets/widgets.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;

  const RoomCard({super.key, required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final priceInMillions = room.price / 1000000;
    final infoText =
        "${priceInMillions.toStringAsFixed(1)} Tr/tháng • ${room.area}m²";
    final firstImage = room.images.isNotEmpty ? room.images[0] : "";

    return Container(
      color: Colors.white,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: firstImage.isNotEmpty
                          ? Image.network(
                              "${ApiConstants.serverUrl}/uploads/rooms/$firstImage",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: const Color(0xFFF8F9FA),
                                    child: const Icon(
                                      Icons.meeting_room_outlined,
                                      color: Colors.black12,
                                      size: 30,
                                    ),
                                  ),
                            )
                          : Container(
                              color: const Color(0xFFF8F9FA),
                              child: const Icon(
                                Icons.meeting_room_outlined,
                                color: Colors.black12,
                                size: 30,
                              ),
                            ),
                    ),
                  ),
                ),
                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                room.roomName.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFF263238),
                                ),
                              ),
                            ),
                            AppStatusBadge(status: room.status),
                          ],
                        ),

                        CardInfoRow(
                          icon: Icons.home_outlined,
                          text: room.houseName ?? "N/A",
                        ),

                        // Tenant or Price/Area
                        if (room.customerName != null &&
                            room.customerName!.isNotEmpty) ...[
                          CardInfoRow(
                            icon: Icons.person,
                            text: room.customerName!,
                          ),
                          CardInfoRow(
                            icon: Icons.phone_android_rounded,
                            text: room.customerPhone ?? "Chưa có SĐT",
                          ),
                        ] else ...[
                          CardInfoRow(
                            icon: Icons.monetization_on_outlined,
                            text:
                                "${(room.price / 1000000).toString().replaceAll(RegExp(r'\.0$'), '')} Tr/tháng",
                          ),
                          CardInfoRow(
                            icon: Icons.aspect_ratio,
                            text:
                                "${room.area.toString().replaceAll(RegExp(r'\.0$'), '')} m²",
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
