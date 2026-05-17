import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/statistics_model.dart';
import '../../../services/statistics_service.dart';

final statisticsProvider = StateNotifierProvider.family<StatisticsNotifier, AsyncValue<StatisticsModel>, int>((ref, houseId) {
  return StatisticsNotifier(houseId);
});

class StatisticsNotifier extends StateNotifier<AsyncValue<StatisticsModel>> {
  final int houseId;
  int currentYear = DateTime.now().year;

  StatisticsNotifier(this.houseId) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats({int? year}) async {
    if (year != null) currentYear = year;
    
    state = const AsyncValue.loading();
    try {
      final stats = await StatisticsService.getStatsSummary(houseId: houseId, year: currentYear);
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void changeYear(int year) {
    loadStats(year: year);
  }
}
