import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eztro/services/house_service.dart';
import 'package:eztro/services/auth_service.dart';
import 'package:eztro/models/house_model.dart';
import 'package:eztro/models/user_model.dart';
import 'package:eztro/core/widgets/widgets.dart';
import 'package:eztro/core/constants/app_colors.dart';
import 'package:eztro/views/house/list/widgets/house_list_skeleton.dart';
import 'package:eztro/views/room/create/create_room_screen.dart';
import 'package:eztro/views/room/detail/room_detail_screen.dart';
import 'package:eztro/views/room/providers/room_notifier.dart';
import 'package:eztro/views/room/providers/room_filter_provider.dart';
import 'package:eztro/views/room/list/widgets/room_card.dart';
import 'package:eztro/models/room_model.dart';

class RoomListScreen extends ConsumerStatefulWidget {
  final int houseId;
  final String houseName;

  const RoomListScreen({
    super.key,
    required this.houseId,
    required this.houseName,
  });

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  late int currentHouseId;
  late String currentHouseName;
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;
  UserModel? currentUser;
  List<HouseModel> houses = [];

  @override
  void initState() {
    super.initState();
    currentHouseId = widget.houseId;
    currentHouseName = widget.houseName;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    currentUser = await AuthService.getCurrentUser();
    final houseData = await HouseService.getHouses();
    if (mounted) setState(() => houses = houseData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredRooms = ref.watch(
      filteredRoomsProvider(houseId: currentHouseId),
    );
    final roomsAsync = ref.watch(roomNotifierProvider(houseId: currentHouseId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'DANH SÁCH PHÒNG',
        onBack: () => Navigator.pop(context),
        isSearching: isSearching,
        searchController: _searchController,
        onSearchToggle: () => setState(() {
          isSearching = !isSearching;
          if (!isSearching) {
            _searchController.clear();
            ref.read(roomFilterNotifierProvider.notifier).setSearchQuery("");
          }
        }),
        onSearchChanged: (val) =>
            ref.read(roomFilterNotifierProvider.notifier).setSearchQuery(val),
      ),
      floatingActionButton:
          (currentUser?.role == 'admin' || currentUser?.role == 'landlord')
          ? FloatingActionButton(
              onPressed: () async {
                bool? refresh = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
                );
                if (refresh == true) {
                  ref
                      .read(
                        roomNotifierProvider(houseId: currentHouseId).notifier,
                      )
                      .refresh(houseId: currentHouseId);
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          AppFilterBar(
            pillItems: _getPillItems(roomsAsync.value ?? []),
            selectedPillValue: ref.watch(roomFilterNotifierProvider).status,
            onPillSelected: (val) =>
                ref.read(roomFilterNotifierProvider.notifier).setStatus(val),
            isEqualWidth: true,
            dropdownItems: [
              CommonFilters.houseFilter(
                context: context,
                houses: houses,
                currentHouseId: currentHouseId,
                currentHouseName: currentHouseName,
                showAllOption: true,
                onChanged: (id, name) {
                  setState(() {
                    currentHouseId = id;
                    currentHouseName = name;
                  });
                  ref.read(roomFilterNotifierProvider.notifier).clear();
                },
              ),
              CommonFilters.priceFilter(
                context: context,
                minPrice: ref.watch(roomFilterNotifierProvider).minPrice,
                maxPrice: ref.watch(roomFilterNotifierProvider).maxPrice,
                onChanged: (min, max) {
                  ref
                      .read(roomFilterNotifierProvider.notifier)
                      .setPriceRange(min, max);
                },
              ),
            ],
          ),
          Expanded(
            child: roomsAsync.when(
              data: (_) {
                if (filteredRooms.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(
                          roomNotifierProvider(
                            houseId: currentHouseId,
                          ).notifier,
                        )
                        .refresh(houseId: currentHouseId),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: const EmptyStateWidget(
                              icon: Icons.meeting_room_outlined,
                              title: "Chưa tìm thấy phòng nào",
                              subtitle:
                                  "Dữ liệu phòng của nhà trọ này sẽ hiện tại đây",
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(
                        roomNotifierProvider(houseId: currentHouseId).notifier,
                      )
                      .refresh(houseId: currentHouseId),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: filteredRooms.length,
                    separatorBuilder: (context, index) => const AppListSeparator(),
                    itemBuilder: (context, index) => RoomCard(
                      room: filteredRooms[index],
                      onTap: () async {
                        bool? refresh = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoomDetailScreen(
                              roomId: filteredRooms[index].id,
                              houseId: filteredRooms[index].houseId,
                            ),
                          ),
                        );
                        if (refresh == true) {
                          ref
                              .read(
                                roomNotifierProvider(
                                  houseId: currentHouseId,
                                ).notifier,
                              )
                              .refresh(houseId: currentHouseId);
                        }
                      },
                    ),
                  ),
                );
              },
              loading: () => const HouseListSkeleton(),
              error: (err, stack) => Center(child: Text("Lỗi: $err")),
            ),
          ),
        ],
      ),
    );
  }

  List<FilterPillItem> _getPillItems(List<RoomModel> rooms) {
    return [
      FilterPillItem(
        label: "Tất cả",
        icon: Icons.grid_view_rounded,
        color: Colors.blue,
        value: "all",
        count: 0,
      ),
      FilterPillItem(
        label: "Trống",
        icon: Icons.door_front_door_outlined,
        color: Colors.green,
        value: "empty",
        count: 0,
      ),
      FilterPillItem(
        label: "Đang ở",
        icon: Icons.person_outline,
        color: Colors.orange,
        value: "available",
        count: 0,
      ),
      FilterPillItem(
        label: "Đã cọc",
        icon: Icons.bookmark_added_outlined,
        color: Colors.blue,
        value: "deposited",
        count: 0,
      ),
    ];
  }
}
