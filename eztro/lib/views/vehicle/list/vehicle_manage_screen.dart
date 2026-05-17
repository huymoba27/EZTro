import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/house_service.dart';
import '../../../services/room_service.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../models/house_model.dart';
import '../../../models/room_model.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/vehicle_card.dart';
import '../create/create_vehicle_screen.dart';
import '../providers/vehicle_notifier.dart';
import '../providers/vehicle_filter_provider.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../house/list/widgets/house_list_skeleton.dart';

class VehicleManageScreen extends ConsumerStatefulWidget {
  const VehicleManageScreen({super.key});

  @override
  ConsumerState<VehicleManageScreen> createState() =>
      _VehicleManageScreenState();
}

class _VehicleManageScreenState extends ConsumerState<VehicleManageScreen> {
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  List<HouseModel> allHouses = [];
  List<RoomModel> roomsInHouse = [];

  HouseModel? selectedHouse;
  RoomModel? selectedRoom;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final houses = await HouseService.getHouses();
      if (mounted) setState(() => allHouses = houses);
    } catch (e) {
      debugPrint("Lỗi tải danh sách nhà: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(filteredVehiclesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'QUẢN LÝ XE',
        isSearching: isSearching,
        searchController: searchController,
        onSearchChanged: (v) => ref.read(vehicleFilterNotifierProvider.notifier).updateQuery(v),
        onSearchToggle: () => setState(() {
          isSearching = !isSearching;
          if (!isSearching) {
            searchController.clear();
            ref.read(vehicleFilterNotifierProvider.notifier).updateQuery('');
          }
        }),
        onBack: () => Navigator.pop(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateVehicleScreen(),
            ),
          );
          if (result == true) {
            ref.read(vehicleNotifierProvider.notifier).refresh();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          AppFilterBar(
            dropdownItems: [
              CommonFilters.houseFilter(
                context: context,
                houses: allHouses,
                currentHouseId: selectedHouse?.id ?? 0,
                currentHouseName: selectedHouse?.houseName ?? "Tất cả nhà",
                showAllOption: true,
                onChanged: (id, name) async {
                  if (id == 0) {
                    setState(() {
                      selectedHouse = null;
                      selectedRoom = null;
                      roomsInHouse = [];
                    });
                    ref.read(vehicleFilterNotifierProvider.notifier).updateHouse(null);
                    ref.read(vehicleFilterNotifierProvider.notifier).updateRoom(null);
                  } else {
                    final house = allHouses.firstWhere((h) => h.id == id);
                    setState(() {
                      selectedHouse = house;
                      selectedRoom = null;
                    });
                    ref.read(vehicleFilterNotifierProvider.notifier).updateHouse(id);
                    ref.read(vehicleFilterNotifierProvider.notifier).updateRoom(null);

                    final rooms = await RoomService.getOccupiedRoomsByHouse(houseId: id);
                    if (mounted) setState(() => roomsInHouse = rooms);
                  }
                },
              ),
              CommonFilters.roomFilter(
                context: context,
                rooms: roomsInHouse,
                selectedRoomName: selectedRoom?.roomName,
                subtitle: selectedHouse != null ? "Lọc xe tại ${selectedHouse!.houseName}" : "Lọc xe theo phòng",
                emptyMessage: "Vui lòng chọn Nhà trước!",
                onChanged: (roomName) {
                  setState(() {
                    if (roomName == null) {
                      selectedRoom = null;
                      ref.read(vehicleFilterNotifierProvider.notifier).updateRoom(null);
                    } else {
                      final found = roomsInHouse.where((r) => r.roomName == roomName);
                      if (found.isNotEmpty) {
                        selectedRoom = found.first;
                        ref.read(vehicleFilterNotifierProvider.notifier).updateRoom(selectedRoom!.id);
                      }
                    }
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: vehiclesAsync.when(
              loading: () => const HouseListSkeleton(),
              error: (err, stack) => Center(child: Text("Lỗi: $err")),
              data: (vehicles) => RefreshIndicator(
                onRefresh: () =>
                    ref.read(vehicleNotifierProvider.notifier).refresh(),
                color: AppColors.primary,
                child: vehicles.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.only(top: 4, bottom: 80),
                        itemCount: vehicles.length,
                        separatorBuilder: (context, index) => const AppListSeparator(),
                        itemBuilder: (context, index) {
                          final item = vehicles[index];
                          return VehicleCard(
                            vehicle: item,
                            onDelete: () => _handleDelete(item.id),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDelete(int vehicleId) {
    DialogHelper.showConfirmDialog(
      context: context,
      title: "Xóa xe",
      message: "Bạn muốn xóa phương tiện này?",
      onConfirm: () async {
        final success = await ref
            .read(vehicleNotifierProvider.notifier)
            .deleteVehicle(vehicleId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã xóa phương tiện thành công")),
          );
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return DialogHelper.buildEmptyState(
      icon: Icons.motorcycle_outlined,
      title: "Không có dữ liệu phương tiện",
      subtitle: "Dữ liệu xe của khách sẽ hiển thị tại đây",
    );
  }
}
