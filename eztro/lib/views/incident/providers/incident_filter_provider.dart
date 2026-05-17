import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/incident_model.dart';
import 'incident_notifier.dart';

part 'incident_filter_provider.g.dart';

class IncidentFilterState {
  final String status;
  final int? houseId;
  final String? houseName; // Added houseName for filtering
  final int? roomId;
  final String? searchQuery;

  IncidentFilterState({
    this.status = 'all',
    this.houseId,
    this.houseName,
    this.roomId,
    this.searchQuery,
  });

  IncidentFilterState copyWith({
    String? status,
    int? houseId,
    String? houseName,
    int? roomId,
    String? searchQuery,
  }) {
    return IncidentFilterState(
      status: status ?? this.status,
      houseId: houseId ?? this.houseId,
      houseName: houseName ?? this.houseName,
      roomId: roomId ?? this.roomId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

@riverpod
class IncidentFilterNotifier extends _$IncidentFilterNotifier {
  @override
  IncidentFilterState build() => IncidentFilterState();

  void setStatus(String status) => state = state.copyWith(status: status);
  void setHouse(int? houseId, String? houseName) => 
      state = state.copyWith(houseId: houseId, houseName: houseName, roomId: null);
  void setRoomId(int? roomId) => state = state.copyWith(roomId: roomId);
  void setSearchQuery(String? query) => state = state.copyWith(searchQuery: query);
  void clear() => state = IncidentFilterState();
}

@riverpod
AsyncValue<List<IncidentModel>> filteredIncidents(FilteredIncidentsRef ref) {
  final incidentsAsync = ref.watch(incidentNotifierProvider);
  final filter = ref.watch(incidentFilterNotifierProvider);

  return incidentsAsync.whenData((incidents) {
    return incidents.where((i) {
      bool matchStatus = filter.status == 'all' || i.status == filter.status;
      
      // Filter by houseName if houseId is provided (as fallback since model lacks houseId)
      bool matchHouse = filter.houseId == null || filter.houseId == 0 || i.houseName == filter.houseName;
      
      bool matchSearch = filter.searchQuery == null || 
          i.title.toLowerCase().contains(filter.searchQuery!.toLowerCase()) ||
          i.description.toLowerCase().contains(filter.searchQuery!.toLowerCase());
          
      return matchStatus && matchHouse && matchSearch;
    }).toList();
  });
}
