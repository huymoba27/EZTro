import 'package:eztro/models/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/contract_model.dart';
import '../../../services/contract_service.dart';
import '../../auth/providers/auth_provider.dart';

part 'contract_notifier.g.dart';

@riverpod
class ContractNotifier extends _$ContractNotifier {
  @override
  Future<List<ContractModel>> build() async {
    final user = ref.watch(authProvider);
    return _fetchData(user);
  }

  Future<List<ContractModel>> _fetchData(UserModel? user) async {
    // Giá trị houseId = 0 để lấy tất cả theo mặc định
    return await ContractService.getContracts(
      houseId: 0,
      userId: user?.id,
      role: user?.role,
      managedHouseId: user?.managedHouseId,
    );
  }

  // Làm mới danh sách
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  // Thanh lý hợp đồng
  Future<Map<String, dynamic>> deleteContract({
    required int roomId,
    required int contractId,
  }) async {
    final res = await ContractService.deleteContract(
      roomId: roomId,
      contractId: contractId,
    );
    if (res['status'] == 'success') {
      await refresh();
    }
    return res;
  }
}
