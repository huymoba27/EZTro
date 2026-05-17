import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/house_model.dart';
import '../../../services/house_service.dart';
import '../../auth/providers/auth_provider.dart';

part 'house_notifier.g.dart';

@riverpod
class HouseNotifier extends _$HouseNotifier {
  @override
  Future<List<HouseModel>> build() async {
    // Chỉ watch ở build để tự động rebuild khi user thay đổi
    final user = ref.watch(authProvider);
    return await HouseService.getHouses(
      userId: user?.id,
      role: user?.role,
      managedHouseId: user?.managedHouseId,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<Map<String, dynamic>> deleteHouse(int houseId) async {
    final result = await HouseService.deleteHouse(houseId);
    if (result['status'] == 'success') {
      refresh();
    }
    return result;
  }
}
