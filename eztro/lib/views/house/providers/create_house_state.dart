import 'package:image_picker/image_picker.dart';

class CreateHouseState {
  final bool isLoading;
  final String selectedCity;
  final String selectedWard;
  final String selectedStatus;
  final List<int> selectedAmenityIds;
  final XFile? imageFile;
  final double latitude;
  final double longitude;
  final List<Map<String, dynamic>> cities;
  final List<Map<String, dynamic>> subUnits; // Wards from API v2
  final List<Map<String, dynamic>> allAmenities;

  CreateHouseState({
    this.isLoading = false,
    this.selectedCity = "Chọn Tỉnh/TP",
    this.selectedWard = "Chọn Phường/Xã/Khu vực",
    this.selectedStatus = "active",
    this.selectedAmenityIds = const [],
    this.imageFile,
    this.latitude = 10.0385,
    this.longitude = 105.7876,
    this.cities = const [],
    this.subUnits = const [],
    this.allAmenities = const [],
  });

  CreateHouseState copyWith({
    bool? isLoading,
    String? selectedCity,
    String? selectedWard,
    String? selectedStatus,
    List<int>? selectedAmenityIds,
    XFile? imageFile,
    double? latitude,
    double? longitude,
    List<Map<String, dynamic>>? cities,
    List<Map<String, dynamic>>? subUnits,
    List<Map<String, dynamic>>? allAmenities,
  }) {
    return CreateHouseState(
      isLoading: isLoading ?? this.isLoading,
      selectedCity: selectedCity ?? this.selectedCity,
      selectedWard: selectedWard ?? this.selectedWard,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedAmenityIds: selectedAmenityIds ?? this.selectedAmenityIds,
      imageFile: imageFile ?? this.imageFile,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cities: cities ?? this.cities,
      subUnits: subUnits ?? this.subUnits,
      allAmenities: allAmenities ?? this.allAmenities,
    );
  }
}
