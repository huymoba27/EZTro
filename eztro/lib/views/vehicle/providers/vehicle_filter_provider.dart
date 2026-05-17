import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/vehicle_model.dart';
import 'vehicle_notifier.dart';

part 'vehicle_filter_provider.g.dart';

// 1. Provider lưu trữ trạng thái bộ lọc
class VehicleFilter {
  final String query;
  final int? houseId;
  final int? roomId;

  VehicleFilter({this.query = '', this.houseId, this.roomId});

  VehicleFilter copyWith({String? query, int? houseId, int? roomId}) {
    return VehicleFilter(
      query: query ?? this.query,
      houseId: houseId == -1 ? null : (houseId ?? this.houseId), // -1 là reset
      roomId: roomId == -1 ? null : (roomId ?? this.roomId),
    );
  }
}

@riverpod
class VehicleFilterNotifier extends _$VehicleFilterNotifier {
  @override
  VehicleFilter build() => VehicleFilter();

  void updateQuery(String query) => state = state.copyWith(query: query);
  void updateHouse(int? houseId) => state = state.copyWith(houseId: houseId);
  void updateRoom(int? roomId) => state = state.copyWith(roomId: roomId);
  void reset() => state = VehicleFilter();
}

// 2. Provider tính toán danh sách đã lọc
@riverpod
AsyncValue<List<VehicleModel>> filteredVehicles(FilteredVehiclesRef ref) {
  final vehiclesAsync = ref.watch(vehicleNotifierProvider);
  final filter = ref.watch(vehicleFilterNotifierProvider);

  return vehiclesAsync.whenData((vehicles) {
    return vehicles.where((v) {
      final matchesSearch = filter.query.isEmpty ||
          v.plateNumber.toLowerCase().contains(filter.query.toLowerCase()) ||
          v.tenantName.toLowerCase().contains(filter.query.toLowerCase());
      
      final matchesHouse = filter.houseId == null || v.houseId == filter.houseId;
      final matchesRoom = filter.roomId == null || v.roomId == filter.roomId;

      return matchesSearch && matchesHouse && matchesRoom;
    }).toList();
  });
}
