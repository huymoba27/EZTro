import 'package:flutter/material.dart';
import '../../../models/vehicle_model.dart';
import '../detail/vehicle_detail_screen.dart';
import '../detail/update_vehicle_screen.dart';
import 'package:eztro/core/widgets/widgets.dart';

class VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onDelete;

  const VehicleCard({super.key, required this.vehicle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    String type = vehicle.vehicleType.toLowerCase();
    IconData vehicleIcon = Icons.motorcycle_rounded;
    Color iconColor = Colors.blue;

    if (type.contains("đạp")) {
      vehicleIcon = Icons.directions_bike_rounded;
      iconColor = Colors.teal;
    } else if (type.contains("ô tô")) {
      vehicleIcon = Icons.directions_car_rounded;
      iconColor = Colors.indigo;
    }

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailScreen(
                vehicle: vehicle,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UpdateVehicleScreen(vehicle: vehicle.toJson()),
                    ),
                  );
                },
                onDelete: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar Circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(vehicleIcon, color: iconColor, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plateNumber.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF263238),
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    CardInfoRow(
                      icon: Icons.person_outline,
                      text: vehicle.tenantName,
                    ),
                    const SizedBox(height: 8),
                    CardInfoRow(
                      icon: Icons.meeting_room_outlined,
                      text: "${vehicle.roomName} - ${vehicle.houseName}",
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
