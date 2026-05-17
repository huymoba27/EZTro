import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/room_model.dart';
import 'room_notifier.dart';

part 'room_filter_provider.g.dart';

class RoomFilter {
  final String status; // 'all', 'empty', 'available', 'full', 'fixing'
  final String searchQuery;
  final double? minPrice;
  final double? maxPrice;

  RoomFilter({this.status = 'all', this.searchQuery = "", this.minPrice, this.maxPrice});

  RoomFilter copyWith({
    String? status,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    bool setMinPrice = false,
    bool setMaxPrice = false,
  }) {
    return RoomFilter(
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
      minPrice: setMinPrice ? minPrice : (minPrice ?? this.minPrice),
      maxPrice: setMaxPrice ? maxPrice : (maxPrice ?? this.maxPrice),
    );
  }
}

@riverpod
class RoomFilterNotifier extends _$RoomFilterNotifier {
  @override
  RoomFilter build() {
    return RoomFilter();
  }

  void setStatus(String status) {
    state = state.copyWith(status: status);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setPriceRange(double? min, double? max) {
    state = state.copyWith(
      minPrice: min,
      maxPrice: max,
      setMinPrice: true,
      setMaxPrice: true,
    );
  }

  void clear() {
    state = RoomFilter();
  }
}

@riverpod
List<RoomModel> filteredRooms(FilteredRoomsRef ref, {int houseId = 0}) {
  final roomsAsync = ref.watch(roomNotifierProvider(houseId: houseId));
  final filter = ref.watch(roomFilterNotifierProvider);

  return roomsAsync.maybeWhen(
    data: (rooms) {
      return rooms.where((room) {
        bool matchesStatus = filter.status == 'all';
        
        if (filter.status != 'all') {
          if (filter.status == 'empty') {
            // Phòng trống bao gồm cả trống và đang đăng tin
            matchesStatus = room.status == 'empty' || room.status == 'posted';
          } else if (filter.status == 'available') {
            // Đang ở bao gồm cả available và full
            matchesStatus = room.status == 'available' || room.status == 'full';
          } else {
            matchesStatus = room.status == filter.status;
          }
        }
        
        final query = filter.searchQuery.toLowerCase();
        final matchesSearch = query.isEmpty ||
            room.roomName.toLowerCase().contains(query) ||
            (room.customerName?.toLowerCase().contains(query) ?? false) ||
            (room.customerPhone?.contains(query) ?? false);

        bool matchesPrice = true;
        if (filter.minPrice != null) matchesPrice = matchesPrice && room.price >= filter.minPrice!;
        if (filter.maxPrice != null) matchesPrice = matchesPrice && room.price <= filter.maxPrice!;

        return matchesStatus && matchesSearch && matchesPrice;
      }).toList();
    },
    orElse: () => [],
  );
}
