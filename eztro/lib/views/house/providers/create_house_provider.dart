import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/address_service.dart';
import '../../../services/house_service.dart';
import 'create_house_state.dart';

class CreateHouseNotifier extends StateNotifier<CreateHouseState> {
  CreateHouseNotifier() : super(CreateHouseState()) {
    loadCities();
    loadAmenities();
  }

  Future<void> loadCities() async {
    final cities = await AddressService.getCities();
    state = state.copyWith(cities: cities);
  }

  Future<void> loadAmenities() async {
    final amenities = await HouseService.getAmenities();
    state = state.copyWith(allAmenities: amenities);
  }

  Future<void> onCityChanged(int code, String cityName) async {
    state = state.copyWith(
      selectedCity: cityName,
      selectedWard: "Chọn Phường/Xã/Khu vực",
      subUnits: [],
      isLoading: true,
    );
    final subUnits = await AddressService.getSubUnits(code);
    state = state.copyWith(subUnits: subUnits, isLoading: false);
  }

  void onWardChanged(String wardName) {
    state = state.copyWith(selectedWard: wardName);
  }

  void onStatusChanged(String status) {
    state = state.copyWith(selectedStatus: status);
  }

  void toggleAmenity(int id) {
    final current = List<int>.from(state.selectedAmenityIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = state.copyWith(selectedAmenityIds: current);
  }

  void setImage(XFile? file) {
    state = state.copyWith(imageFile: file);
  }

  Future<void> updateLocationFull({
    required double lat,
    required double lng,
    String? city,
    String? ward,
  }) async {
    state = state.copyWith(latitude: lat, longitude: lng, isLoading: true);

    // Auto-match codes for v2 API
    if (city != null) {
      final cityCode = await AddressService.findCodeByName(city, state.cities);
      if (cityCode != null) {
        final subUnits = await AddressService.getSubUnits(cityCode);
        state = state.copyWith(selectedCity: city, subUnits: subUnits);

        if (ward != null) {
          final wardCode = await AddressService.findCodeByName(ward, subUnits);
          if (wardCode != null) {
            state = state.copyWith(selectedWard: ward);
          }
        }
      }
    }

    state = state.copyWith(isLoading: false);
  }

  void setLocation(double lat, double lng) {
    state = state.copyWith(latitude: lat, longitude: lng);
  }

  void setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void reset() {
    state = CreateHouseState(cities: state.cities);
  }

  Future<void> initForEdit(
    String city,
    String ward,
    List<int> amenityIds,
    double lat,
    double lng,
  ) async {
    state = state.copyWith(
      selectedCity: city,
      selectedWard: ward,
      selectedAmenityIds: amenityIds,
      latitude: lat,
      longitude: lng,
      isLoading: true,
    );

    // Attempt to load hierarchy
    final cityCode = await AddressService.findCodeByName(city, state.cities);
    if (cityCode != null) {
      final subUnits = await AddressService.getSubUnits(cityCode);
      state = state.copyWith(subUnits: subUnits);
    }

    state = state.copyWith(isLoading: false);
  }
}

final createHouseProvider =
    StateNotifierProvider.autoDispose<CreateHouseNotifier, CreateHouseState>((
      ref,
    ) {
      return CreateHouseNotifier();
    });
