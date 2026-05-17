import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/tenant_model.dart';
import '../../../services/tenant_service.dart';

part 'tenant_notifier.g.dart';

@riverpod
class TenantNotifier extends _$TenantNotifier {
  @override
  Future<List<TenantModel>> build() async {
    return _fetchTenants();
  }

  Future<List<TenantModel>> _fetchTenants() async {
    return await TenantService.getAllTenants();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTenants());
  }

  Future<Map<String, dynamic>> deleteTenant(int tenantId) async {
    final result = await TenantService.deleteTenant(tenantId: tenantId);
    if (result['status'] == 'success') {
      refresh();
    }
    return result;
  }
}
