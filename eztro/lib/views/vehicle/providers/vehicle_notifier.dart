import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/vehicle_model.dart';
import '../../../services/vehicle_service.dart';

part 'vehicle_notifier.g.dart';

@riverpod
class VehicleNotifier extends _$VehicleNotifier {
  @override
  Future<List<VehicleModel>> build() async {
    return await VehicleService.getAllVehicles();
  }

  // 1. Làm mới dữ liệu
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => VehicleService.getAllVehicles());
  }

  // 2. Thêm xe mới
  Future<bool> addVehicle({
    required int tenantId, 
    required String plate, 
    required String type,
  }) async {
    final res = await VehicleService.addVehicle(
      tenantId: tenantId, 
      plate: plate, 
      type: type
    );
    
    if (res['status'] == 'success') {
      await refresh();
      return true;
    }
    return false;
  }

  // 3. Xóa xe
  Future<bool> deleteVehicle(int id) async {
    final res = await VehicleService.deleteVehicle(id: id);
    if (res['status'] == 'success') {
      // Tối ưu: Xóa trực tiếp trong state hiện tại để UI mượt mà
      if (state.hasValue) {
        final currentVehicles = state.value!;
        state = AsyncValue.data(
          currentVehicles.where((v) => v.id != id).toList()
        );
      }
      return true;
    }
    return false;
  }
}
