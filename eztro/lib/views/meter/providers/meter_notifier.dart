import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/meter_service.dart';

class MeterFilter {
  final int houseId;
  final int month;
  final int year;
  final String status;

  MeterFilter({
    required this.houseId,
    required this.month,
    required this.year,
    this.status = 'all',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeterFilter &&
          runtimeType == other.runtimeType &&
          houseId == other.houseId &&
          month == other.month &&
          year == other.year &&
          status == other.status;

  @override
  int get hashCode =>
      houseId.hashCode ^ month.hashCode ^ year.hashCode ^ status.hashCode;
}

class MeterNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  MeterNotifier() : super(const AsyncValue.loading());

  Future<void> loadMeterData({required MeterFilter filter}) async {
    state = const AsyncValue.loading();
    try {
      final data = await MeterService.getMeterStatusByHouse(
        houseId: filter.houseId,
        month: filter.month,
        year: filter.year,
      );
      if (!mounted) return;
      state = AsyncValue.data(data);
    } catch (e, stack) {
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh({required MeterFilter filter}) async {
    try {
      final data = await MeterService.getMeterStatusByHouse(
        houseId: filter.houseId,
        month: filter.month,
        year: filter.year,
      );
      if (!mounted) return;
      state = AsyncValue.data(data);
    } catch (e, stack) {
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    }
  }
}

final meterNotifierProvider =
    StateNotifierProvider.autoDispose.family<
      MeterNotifier,
      AsyncValue<List<Map<String, dynamic>>>,
      MeterFilter
    >((ref, filter) {
      final notifier = MeterNotifier();
      notifier.loadMeterData(filter: filter);
      return notifier;
    });

// --- Search Filter ---
final meterSearchProvider = StateProvider<String>((ref) => "");

final filteredMeterDataProvider =
    Provider.autoDispose.family<List<Map<String, dynamic>>, MeterFilter>((ref, filter) {
      final asyncData = ref.watch(meterNotifierProvider(filter));
      final query = ref.watch(meterSearchProvider).toLowerCase();

      return asyncData.when(
        data: (list) {
          // 1. Lọc theo trạng thái & Chỉ hiện phòng có hợp đồng đang hoạt động
          Iterable<Map<String, dynamic>> result = list.where((r) {
            return r['contract_id'] != null && r['contract_id'].toString() != '0';
          });

          if (filter.status == 'recorded') {
            result = result.where((r) => r['date_done'] != null);
          } else if (filter.status == 'pending') {
            result = result.where((r) => r['date_done'] == null);
          }

          // 2. Tìm kiếm theo từ khóa
          if (query.isNotEmpty) {
            result = result.where(
              (r) => r['room_name'].toString().toLowerCase().contains(query),
            );
          }

          return result.toList();
        },
        loading: () => [],
        error: (_, _) => [],
      );
    });
