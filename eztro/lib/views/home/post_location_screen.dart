import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../core/constants/app_colors.dart';

class PostLocationScreen extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String address;
  final String title;

  const PostLocationScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapbox View
          MapWidget(
            key: const ValueKey("full_map"),
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(longitude, latitude)),
              zoom: 15.0,
            ),
            onMapCreated: (mapboxMap) async {
              // Disable unnecessary UI
              await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
              await mapboxMap.attribution.updateSettings(AttributionSettings(enabled: false));
              await mapboxMap.logo.updateSettings(LogoSettings(enabled: false));
            },
          ),

          // Static Pin in Center
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 56,
                  ),
                  const SizedBox(height: 40), // Offset to align pin tip with center
                ],
              ),
            ),
          ),

          // Custom App Bar (Floating)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
              ),
            ),
          ),

          // Bottom Info Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "VỊ TRÍ PHÒNG TRỌ",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.4,
                          ),
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
    );
  }
}
