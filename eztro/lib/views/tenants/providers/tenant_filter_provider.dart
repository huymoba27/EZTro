import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/tenant_model.dart';
import 'tenant_notifier.dart';

part 'tenant_filter_provider.g.dart';

class TenantFilter {
  final int houseId;
  final String roomName;
  final String searchQuery;
  final String status;

  TenantFilter({
    this.houseId = 0,
    this.roomName = "",
    this.searchQuery = "",
    this.status = "all",
  });

  TenantFilter copyWith({int? houseId, String? roomName, String? searchQuery, String? status}) {
    return TenantFilter(
      houseId: houseId ?? this.houseId,
      roomName: roomName ?? this.roomName,
      searchQuery: searchQuery ?? this.searchQuery,
      status: status ?? this.status,
    );
  }
}

@riverpod
class TenantFilterNotifier extends _$TenantFilterNotifier {
  @override
  TenantFilter build() {
    return TenantFilter();
  }

  void setHouseId(int houseId) {
    state = state.copyWith(houseId: houseId, roomName: "");
  }

  void setRoomName(String roomName) {
    state = state.copyWith(roomName: roomName);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatus(String status) {
    state = state.copyWith(status: status);
  }

  void clear() {
    state = TenantFilter();
  }
}

@riverpod
List<TenantModel> filteredTenants(FilteredTenantsRef ref) {
  final tenantsAsync = ref.watch(tenantNotifierProvider);
  final filter = ref.watch(tenantFilterNotifierProvider);

  return tenantsAsync.maybeWhen(
    data: (tenants) {
      return tenants.where((tenant) {
        final matchesHouse = filter.houseId == 0 || tenant.houseId == filter.houseId;
        
        final matchesRoom = filter.roomName.isEmpty || tenant.roomName == filter.roomName;

        final matchesStatus = filter.status == 'all' || 
            (filter.status == 'lead' && tenant.isRepresentative == 1) ||
            (filter.status == 'member' && tenant.isRepresentative == 0);

        final query = filter.searchQuery.toLowerCase();
        final matchesSearch = query.isEmpty ||
            tenant.tenantName.toLowerCase().contains(query) ||
            (tenant.phone != null && tenant.phone!.toLowerCase().contains(query));

        return matchesHouse && matchesRoom && matchesStatus && matchesSearch;
      }).toList();
    },
    orElse: () => [],
  );
}
