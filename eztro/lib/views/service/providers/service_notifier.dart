import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/service_model.dart';
import '../../../services/service_manage_service.dart';

class ServiceNotifier extends StateNotifier<AsyncValue<List<ServiceModel>>> {
  ServiceNotifier() : super(const AsyncValue.loading());

  Future<void> loadServices({required int houseId}) async {
    state = const AsyncValue.loading();
    try {
      final services = await ServiceManageService.getServices(houseId: houseId);
      state = AsyncValue.data(services);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh({required int houseId}) async {
    try {
      final services = await ServiceManageService.getServices(houseId: houseId);
      state = AsyncValue.data(services);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final serviceNotifierProvider = StateNotifierProvider.autoDispose
    .family<ServiceNotifier, AsyncValue<List<ServiceModel>>, int>((
      ref,
      houseId,
    ) {
      final notifier = ServiceNotifier();
      notifier.loadServices(houseId: houseId);
      return notifier;
    });

// --- Filter Logic ---
final serviceSearchProvider = StateProvider<String>((ref) => "");

final filteredServicesProvider = Provider.family<List<ServiceModel>, int>((
  ref,
  houseId,
) {
  final servicesAsync = ref.watch(serviceNotifierProvider(houseId));
  final query = ref.watch(serviceSearchProvider).toLowerCase();

  return servicesAsync.when(
    data: (services) => services
        .where((s) => s.serviceName.toLowerCase().contains(query))
        .toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});
