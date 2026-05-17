import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/house_model.dart';
import 'house_notifier.dart';



class HouseFilterState {
  final String status;
  final String city;
  final String managerName;
  final String searchQuery;

  HouseFilterState({
    this.status = 'all',
    this.city = 'all',
    this.managerName = 'all',
    this.searchQuery = '',
  });

  HouseFilterState copyWith({
    String? status,
    String? city,
    String? managerName,
    String? searchQuery,
  }) {
    return HouseFilterState(
      status: status ?? this.status,
      city: city ?? this.city,
      managerName: managerName ?? this.managerName,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class HouseFilterNotifier extends Notifier<HouseFilterState> {
  @override
  HouseFilterState build() {
    return HouseFilterState();
  }

  void setStatus(String status) => state = state.copyWith(status: status);
  void setCity(String city) => state = state.copyWith(city: city);
  void setManager(String manager) =>
      state = state.copyWith(managerName: manager);
  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);

  void clear() => state = HouseFilterState();
}

final houseFilterNotifierProvider =
    NotifierProvider<HouseFilterNotifier, HouseFilterState>(() {
  return HouseFilterNotifier();
});

final filteredHousesListProvider = Provider<List<HouseModel>>((ref) {
  final housesAsync = ref.watch(houseNotifierProvider);
  final filter = ref.watch(houseFilterNotifierProvider);

  return housesAsync.maybeWhen(
    data: (houses) {
      return houses.where((house) {
        // 1. Search Query
        if (filter.searchQuery.isNotEmpty) {
          final query = filter.searchQuery.toLowerCase();
          final matchesName = house.houseName.toLowerCase().contains(query);
          final matchesAddress = house.fullAddress.toLowerCase().contains(query);
          if (!matchesName && !matchesAddress) return false;
        }

        // 2. Status
        if (filter.status != 'all') {
          if (house.status != filter.status) return false;
        }

        // 3. City
        if (filter.city != 'all') {
          if (house.city != filter.city) return false;
        }

        // 4. Manager
        if (filter.managerName != 'all') {
          if ((house.managerName ?? '') != filter.managerName) return false;
        }

        return true;
      }).toList();
    },
    orElse: () => [],
  );
});
