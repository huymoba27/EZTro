import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/receipt_model.dart';
import '../../../services/receipt_service.dart';

class ReceiptFilter {
  final int houseId;
  final int month;
  final int year;

  ReceiptFilter({
    required this.houseId,
    required this.month,
    required this.year,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptFilter &&
          runtimeType == other.runtimeType &&
          houseId == other.houseId &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => houseId.hashCode ^ month.hashCode ^ year.hashCode;
}

class ReceiptNotifier extends StateNotifier<AsyncValue<List<ReceiptModel>>> {
  ReceiptNotifier() : super(const AsyncValue.loading());

  Future<void> loadReceipts({required ReceiptFilter filter}) async {
    state = const AsyncValue.loading();
    try {
      final receipts = await ReceiptService.getReceipts(
        houseId: filter.houseId,
        month: filter.month,
        year: filter.year,
      );
      state = AsyncValue.data(receipts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh({required ReceiptFilter filter}) async {
    try {
      final receipts = await ReceiptService.getReceipts(
        houseId: filter.houseId,
        month: filter.month,
        year: filter.year,
      );
      state = AsyncValue.data(receipts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final receiptNotifierProvider = StateNotifierProvider.autoDispose
    .family<ReceiptNotifier, AsyncValue<List<ReceiptModel>>, ReceiptFilter>((
      ref,
      filter,
    ) {
      final notifier = ReceiptNotifier();
      notifier.loadReceipts(filter: filter);
      return notifier;
    });

// --- UI Helpers (Grouped Data) ---
final groupedReceiptsProvider =
    Provider.family<List<Map<String, dynamic>>, ReceiptFilter>((ref, filter) {
      final asyncReceipts = ref.watch(receiptNotifierProvider(filter));

      return asyncReceipts.when(
        data: (receipts) {
          if (receipts.isEmpty) return [];

          Map<String, List<ReceiptModel>> grouped = {};
          for (var r in receipts) {
            String date = r.receiptDate;
            if (!grouped.containsKey(date)) grouped[date] = [];
            grouped[date]!.add(r);
          }

          var sortedDates = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a));
          List<Map<String, dynamic>> displayItems = [];

          for (var date in sortedDates) {
            final list = grouped[date]!;
            double dayTotal = list.fold(0, (sum, r) => sum + r.amount);

            displayItems.add({
              'type': 'header',
              'date': date,
              'total': dayTotal,
            });
            for (var i = 0; i < list.length; i++) {
              displayItems.add({
                'type': 'item',
                'data': list[i],
                'isLast': i == list.length - 1,
              });
            }
          }
          return displayItems;
        },
        loading: () => [],
        error: (_, _) => [],
      );
    });
