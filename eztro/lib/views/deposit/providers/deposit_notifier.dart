import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/deposit_model.dart';
import '../../../services/deposit_service.dart';

class DepositFilter {
  final int houseId;
  final int month;
  final int year;
  final String status;
  final int userId;
  final String role;

  DepositFilter({
    required this.houseId,
    required this.month,
    required this.year,
    required this.userId,
    this.role = "landlord",
    this.status = "",
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepositFilter &&
          runtimeType == other.runtimeType &&
          houseId == other.houseId &&
          month == other.month &&
          year == other.year &&
          userId == other.userId &&
          role == other.role &&
          status == other.status;

  @override
  int get hashCode =>
      houseId.hashCode ^
      month.hashCode ^
      year.hashCode ^
      userId.hashCode ^
      role.hashCode ^
      status.hashCode;
}

class DepositNotifier extends StateNotifier<AsyncValue<List<DepositModel>>> {
  DepositNotifier() : super(const AsyncValue.loading());

  Future<void> loadDeposits({required DepositFilter filter}) async {
    state = const AsyncValue.loading();
    try {
      final deposits = await DepositService.getDeposits(
        filter.houseId,
        filter.status,
        month: filter.month,
        year: filter.year,
        userId: filter.userId,
        role: filter.role,
      );
      state = AsyncValue.data(deposits);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh({required DepositFilter filter}) async {
    try {
      final deposits = await DepositService.getDeposits(
        filter.houseId,
        filter.status,
        month: filter.month,
        year: filter.year,
        userId: filter.userId,
        role: filter.role,
      );
      state = AsyncValue.data(deposits);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final depositNotifierProvider = StateNotifierProvider.autoDispose
    .family<DepositNotifier, AsyncValue<List<DepositModel>>, DepositFilter>((
      ref,
      filter,
    ) {
      final notifier = DepositNotifier();
      notifier.loadDeposits(filter: filter);
      return notifier;
    });

// --- Search Provider ---
final depositSearchProvider = StateProvider<String>((ref) => "");

final filteredDepositsProvider =
    Provider.family<List<DepositModel>, DepositFilter>((ref, filter) {
      final asyncData = ref.watch(depositNotifierProvider(filter));
      final query = ref.watch(depositSearchProvider).toLowerCase();

      return asyncData.when(
        data: (list) {
          if (query.isEmpty) return list;
          return list
              .where(
                (d) =>
                    d.customerName.toLowerCase().contains(query) ||
                    (d.roomName?.toLowerCase().contains(query) ?? false),
              )
              .toList();
        },
        loading: () => [],
        error: (_, _) => [],
      );
    });
