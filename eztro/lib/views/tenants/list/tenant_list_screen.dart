import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/house_service.dart';
import '../../../services/room_service.dart';
import '../../../core/constants/app_colors.dart';
import 'package:eztro/core/widgets/widgets.dart';
import 'tenant_list_body.dart';
import '../../../models/house_model.dart';
import '../../../models/room_model.dart';
import '../create/add_member_screen.dart';
import '../providers/tenant_notifier.dart';
import '../providers/tenant_filter_provider.dart';

class TenantListScreen extends ConsumerStatefulWidget {
  const TenantListScreen({super.key});

  @override
  ConsumerState<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends ConsumerState<TenantListScreen> {
  List<HouseModel> houses = [];
  List<String> roomNames = [];
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final houseData = await HouseService.getHouses();
      if (mounted) {
        setState(() => houses = houseData);
      }
      _updateRoomList();
    } catch (e) {
      debugPrint("Lỗi tải data ban đầu: $e");
    }
  }

  Future<void> _updateRoomList() async {
    final filter = ref.read(tenantFilterNotifierProvider);
    if (filter.houseId == 0) {
      if (mounted) setState(() => roomNames = []);
      return;
    }

    try {
      final roomData = await RoomService.getRooms(houseId: filter.houseId);
      if (mounted) {
        setState(() {
          roomNames = roomData.map((r) => r.roomName).toList();
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách phòng: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTenants = ref.watch(filteredTenantsProvider);
    final tenantsAsync = ref.watch(tenantNotifierProvider);
    final filter = ref.watch(tenantFilterNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'KHÁCH THUÊ',
        onBack: () => Navigator.pop(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMemberScreen()),
          );
          if (result == true) {
            ref.read(tenantNotifierProvider.notifier).refresh();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFilterBar(
            pillItems: CommonFilters.tenantStatusPills(),
            selectedPillValue: filter.status,
            onPillSelected: (val) =>
                ref.read(tenantFilterNotifierProvider.notifier).setStatus(val),
            isEqualWidth: true,
            showCount: false,
            dropdownItems: [
              CommonFilters.houseFilter(
                context: context,
                houses: houses,
                currentHouseId: filter.houseId,
                currentHouseName: filter.houseId == 0
                    ? "Tất cả nhà"
                    : houses
                          .firstWhere(
                            (h) => h.id == filter.houseId,
                            orElse: () => houses.first,
                          )
                          .houseName,
                onChanged: (id, name) {
                  ref
                      .read(tenantFilterNotifierProvider.notifier)
                      .setHouseId(id);
                  _updateRoomList();
                },
              ),
              CommonFilters.roomFilter(
                context: context,
                rooms: roomNames
                    .map(
                      (r) => RoomModel(
                        id: 0,
                        houseId: 0,
                        roomName: r,
                        price: 0,
                        deposit: 0,
                        status: "",
                        area: 0,
                        maxTenants: 0,
                        images: [],
                      ),
                    )
                    .toList(), // RoomFilter needs RoomModel
                selectedRoomName: filter.roomName.isEmpty
                    ? null
                    : filter.roomName,
                subtitle: "Lọc theo phòng của nhà đã chọn",
                emptyMessage: "Vui lòng chọn nhà trước khi chọn phòng",
                onChanged: (roomName) {
                  ref
                      .read(tenantFilterNotifierProvider.notifier)
                      .setRoomName(roomName ?? "");
                },
              ),
            ],
          ),
          Expanded(
            child: TenantListBody(
              tenants: filteredTenants,
              isLoading: tenantsAsync.isLoading,
              onRefresh: () =>
                  ref.read(tenantNotifierProvider.notifier).refresh(),
            ),
          ),
        ],
      ),
    );
  }
}
