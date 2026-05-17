import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/contract_model.dart';
import 'contract_notifier.dart';

part 'contract_filter_provider.g.dart';

@riverpod
class ContractFilterNotifier extends _$ContractFilterNotifier {
  @override
  Map<String, dynamic> build() {
    return {
      'houseId': 0,
      'status': 'all', // 'all', 'active', 'expired'
      'query': '',
    };
  }

  void updateHouse(int houseId) {
    state = {...state, 'houseId': houseId};
  }

  void updateStatus(String status) {
    state = {...state, 'status': status};
  }

  void updateQuery(String query) {
    state = {...state, 'query': query};
  }
}

@riverpod
AsyncValue<List<ContractModel>> filteredContracts(FilteredContractsRef ref) {
  final contractsAsync = ref.watch(contractNotifierProvider);
  final filter = ref.watch(contractFilterNotifierProvider);

  return contractsAsync.whenData((contracts) {
    return contracts.where((c) {
      // 1. Lọc theo Nhà
      bool matchesHouse = true;
      if (filter['houseId'] != 0) {
        // Giả sử ContractModel có houseId hoặc lọc qua houseName nếu id trùng
        matchesHouse = (c.houseId == filter['houseId']);
      }

      // 2. Lọc theo Trạng thái
      bool matchesStatus = true;
      if (filter['status'] == 'active') {
        matchesStatus = (c.status == 'active');
      } else if (filter['status'] == 'expired') {
        matchesStatus = (c.status != 'active');
      }

      // 3. Lọc theo Từ khóa
      final name = (c.tenantName ?? "").toLowerCase();
      final room = c.roomName.toLowerCase();
      final query = filter['query'].toLowerCase();
      bool matchesQuery = name.contains(query) || room.contains(query);

      return matchesHouse && matchesStatus && matchesQuery;
    }).toList();
  });
}
