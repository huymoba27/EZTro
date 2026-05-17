import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../../core/constants/app_secrets.dart';

/// Kết quả trả về từ màn hình chọn vị trí (Mô hình 2 cấp 2026)
class MapPickerResult {
  final double lat;
  final double lng;
  final String address; // Địa chỉ đầy đủ
  final String? cityName; // Tên Tỉnh/TP
  final String? wardName; // Tên Xã/Phường
  final String? streetName; // Số nhà, tên đường

  MapPickerResult({
    required this.lat,
    required this.lng,
    this.address = '',
    this.cityName,
    this.wardName,
    this.streetName,
  });
}

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialAddressQuery;
  const MapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialAddressQuery,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  MapboxMap? _mapboxMap;
  double _selectedLat = 10.8231;
  double _selectedLng = 106.6297;
  bool _isLoadingLocation = false;
  bool _isGeocoding = false;
  bool _isMapMoving = false;
  String _addressPreview = "Di chuyển bản đồ để ghim vị trí...";

  String? _parsedCity;
  String? _parsedWard;
  String? _parsedStreet;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLat = widget.initialLat!;
      _selectedLng = widget.initialLng!;
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await mapboxMap.attribution.updateSettings(
      AttributionSettings(enabled: false),
    );
    await mapboxMap.logo.updateSettings(LogoSettings(enabled: false));

    if (widget.initialLat == null &&
        widget.initialAddressQuery != null &&
        widget.initialAddressQuery!.isNotEmpty) {
      await _forwardGeocode(widget.initialAddressQuery!);
    } else {
      _reverseGeocode(_selectedLat, _selectedLng);
    }
  }

  Future<void> _forwardGeocode(String address) async {
    try {
      final encoded = Uri.encodeComponent(address);
      final url =
          "https://api.mapbox.com/geocoding/v5/mapbox.places/$encoded.json?country=vn&language=vi&access_token=${AppSecrets.mapboxAccessToken}";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final coords = features[0]['geometry']['coordinates'] as List;
          final lng = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();
          if (mounted) {
            setState(() {
              _selectedLat = lat;
              _selectedLng = lng;
            });
          }
          await _mapboxMap?.flyTo(
            CameraOptions(
              center: Point(coordinates: Position(lng, lat)),
              zoom: 15.0,
            ),
            MapAnimationOptions(duration: 1200),
          );
        }
      }
    } catch (_) {}
    _reverseGeocode(_selectedLat, _selectedLng);
  }

  void _onCameraChanging(CameraChangedEventData data) {
    if (mounted && !_isMapMoving) setState(() => _isMapMoving = true);
  }

  Future<void> _onMapIdle(MapIdleEventData data) async {
    if (_mapboxMap == null) return;
    final camera = await _mapboxMap!.getCameraState();
    final lat = camera.center.coordinates.lat.toDouble();
    final lng = camera.center.coordinates.lng.toDouble();
    if (mounted) {
      setState(() {
        _selectedLat = lat;
        _selectedLng = lng;
        _isMapMoving = false;
      });
    }
    _reverseGeocode(lat, lng);
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    if (mounted) setState(() => _isGeocoding = true);
    try {
      final url =
          "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1&accept-language=vi";
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'TroApp/1.0'},
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final addr = data['address'] as Map<String, dynamic>? ?? {};

        // === 1. Xác định Tỉnh/Thành phố ===
        // Dùng trực tiếp trường 'state' của Nominatim (đã trả về tiếng Việt có dấu)
        String? city = addr['state']?.toString() ?? addr['city']?.toString();

        // === 2. Xác định Khu vực (Phường/Xã/Quận/Huyện) ===
        String? wardSmall; // Phường, Xã, Thị trấn
        String? wardLarge; // Quận, Huyện, Thị xã, Thành phố (cấp huyện)

        for (var entry in addr.entries) {
          final val = entry.value.toString();
          final lVal = val.toLowerCase();
          if (wardSmall == null &&
              (lVal.startsWith('phường') ||
                  lVal.startsWith('xã') ||
                  lVal.startsWith('thị trấn'))) {
            wardSmall = val;
          }
          if (wardLarge == null &&
              (lVal.startsWith('quận') ||
                  lVal.startsWith('huyện') ||
                  lVal.startsWith('thị xã') ||
                  lVal.startsWith('thành phố'))) {
            if (val != city) wardLarge = val;
          }
        }

        // Fallback bằng trường chuẩn của Nominatim
        wardSmall ??=
            addr['quarter']?.toString() ??
            addr['suburb']?.toString() ??
            addr['village']?.toString();
        wardLarge ??=
            addr['county']?.toString() ?? addr['city_district']?.toString();

        // Chọn ward: ưu tiên cấp nhỏ nhất
        final String? ward = wardSmall ?? wardLarge;

        // === 3. Xác định Số nhà / Tên đường ===
        final road = addr['road']?.toString();
        final houseNo = addr['house_number']?.toString();
        String? street;
        if (houseNo != null && road != null) {
          street = "$houseNo $road";
        } else if (road != null)
          street = road;

        // === 4. Ghép chuỗi địa chỉ hiển thị (Dùng Set để tránh trùng lặp nội dung)
        final List<String> parts = [];
        void addUniquePart(String? p) {
          if (p == null || p.isEmpty) return;
          // Kiểm tra xem part này đã tồn tại hoặc là một phần của part khác chưa
          if (!parts.any((existing) => existing.toLowerCase().contains(p.toLowerCase()) || p.toLowerCase().contains(existing.toLowerCase()))) {
            parts.add(p);
          }
        }

        addUniquePart(street);
        addUniquePart(wardSmall);
        addUniquePart(wardLarge);
        addUniquePart(city);

        setState(() {
          _addressPreview = parts.join(', ');
          _parsedCity = city;
          // Ưu tiên wardSmall (Phường/Xã) vì nó cụ thể hơn để khớp dropdown
          _parsedWard = wardSmall ?? wardLarge;
          _parsedStreet = street;
        });
      }
    } catch (e) {
      debugPrint("Geocode error: $e");
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _getMyLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      geo.LocationPermission p = await geo.Geolocator.checkPermission();
      if (p == geo.LocationPermission.denied) {
        p = await geo.Geolocator.requestPermission();
      }
      final pos = await geo.Geolocator.getCurrentPosition();
      await _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(pos.longitude, pos.latitude)),
          zoom: 16,
        ),
        MapAnimationOptions(duration: 1000),
      );
    } catch (_) {}
    if (mounted) setState(() => _isLoadingLocation = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("map_v2"),
            styleUri: MapboxStyles.MAPBOX_STREETS,
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(_selectedLng, _selectedLat)),
              zoom: 14,
            ),
            onMapCreated: _onMapCreated,
            onCameraChangeListener: _onCameraChanging,
            onMapIdleListener: _onMapIdle,
          ),
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _isMapMoving ? 18 : 10,
                    height: _isMapMoving ? 6 : 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.translationValues(
                      0,
                      _isMapMoving ? -12 : 0,
                      0,
                    ),
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 56,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nút Quay lại
          Positioned(
            top: 50,
            left: 16,
            child: _circleBtn(
              Icons.arrow_back_ios_new,
              onTap: () => Navigator.pop(context),
            ),
          ),

          // Nút GPS
          Positioned(
            bottom: 240,
            right: 16,
            child: _circleBtn(
              _isLoadingLocation ? null : Icons.my_location_rounded,
              color: Colors.green[700]!,
              isLoading: _isLoadingLocation,
              onTap: _isLoadingLocation ? null : _getMyLocation,
            ),
          ),

          // Panel thông tin
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    "VỊ TRÍ ĐÃ CHỌN (2026)",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: Colors.blue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _isGeocoding || _isMapMoving
                            ? const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: LinearProgressIndicator(
                                  color: Colors.blue,
                                  backgroundColor: Color(0xFFEEEEEE),
                                ),
                              )
                            : Text(
                                _addressPreview,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isMapMoving || _isGeocoding
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                                MapPickerResult(
                                  lat: _selectedLat,
                                  lng: _selectedLng,
                                  address: _addressPreview,
                                  cityName: _parsedCity,
                                  wardName: _parsedWard,
                                  streetName: _parsedStreet,
                                ),
                              );
                            },
                      child: const Text(
                        "Xác nhận vị trí này",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(
    IconData? icon, {
    VoidCallback? onTap,
    Color color = Colors.black87,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
