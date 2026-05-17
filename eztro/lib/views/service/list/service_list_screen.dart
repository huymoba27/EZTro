import 'package:flutter/material.dart';
import 'package:eztro/core/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/house_service.dart';
import '../../../services/room_service.dart';
import '../../../services/service_manage_service.dart';
import '../../../models/house_model.dart';
import '../../../models/room_model.dart';
import '../../../models/service_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/format_helper.dart';
import '../create/create_service_screen.dart';
import '../../house/list/widgets/house_list_skeleton.dart';
import '../providers/service_notifier.dart';

class ServiceListScreen extends ConsumerStatefulWidget {
  final int houseId;
  final String houseName;

  const ServiceListScreen({
    super.key,
    required this.houseId,
    required this.houseName,
  });

  @override
  ConsumerState<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends ConsumerState<ServiceListScreen> {
  late int currentHouseId;
  late String currentHouseName;
  List<HouseModel> houses = [];
  List<RoomModel> roomsInHouse = [];
  String? selectedRoomName;

  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentHouseId = widget.houseId;
    currentHouseName = widget.houseId == 0 ? "Tất cả nhà" : widget.houseName;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final houseData = await HouseService.getHouses();
    if (mounted) {
      setState(() => houses = houseData);
      if (currentHouseId != 0) {
        _updateRoomList(currentHouseId);
      }
    }
  }

  Future<void> _updateRoomList(int houseId) async {
    if (houseId == 0) {
      setState(() {
        roomsInHouse = [];
        selectedRoomName = null;
      });
      return;
    }
    try {
      final roomData = await RoomService.getRooms(houseId: houseId);
      if (mounted) {
        setState(() {
          roomsInHouse = roomData;
          selectedRoomName = null;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải phòng: $e");
    }
  }

  void _deleteService(ServiceModel service) {
    DialogHelper.showConfirmDialog(
      context: context,
      title: "XÓA DỊCH VỤ",
      message:
          "Bạn có chắc chắn muốn xóa dịch vụ ${service.serviceName}? Dịch vụ đang nằm trong hợp đồng sẽ không thể xóa.",
      onConfirm: () async {
        final res = await ServiceManageService.deleteService(service.id);
        if (!mounted) return;

        if (res['status'] == 'success') {
          await ref
              .read(serviceNotifierProvider(currentHouseId).notifier)
              .refresh(houseId: currentHouseId);
          if (!mounted) return;
          DialogHelper.showSuccess(
            context,
            res['message'] ?? "Xóa dịch vụ thành công",
          );
        } else {
          DialogHelper.showError(
            context,
            res['message'] ?? "Không thể xóa dịch vụ",
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(serviceNotifierProvider(currentHouseId));
    final filteredServices = ref.watch(
      filteredServicesProvider(currentHouseId),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'DỊCH VỤ',
        isSearching: isSearching,
        searchController: _searchController,
        onSearchChanged: (val) =>
            ref.read(serviceSearchProvider.notifier).state = val,
        onSearchToggle: () => setState(() {
          isSearching = !isSearching;
          if (!isSearching) {
            _searchController.clear();
            ref.read(serviceSearchProvider.notifier).state = "";
          }
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool? refresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateServiceScreen()),
          );
          if (refresh == true) {
            ref
                .read(serviceNotifierProvider(currentHouseId).notifier)
                .refresh(houseId: currentHouseId);
          }
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Column(
        children: [
          AppFilterBar(
            dropdownItems: [
              CommonFilters.houseFilter(
                context: context,
                houses: houses,
                currentHouseId: currentHouseId,
                currentHouseName: currentHouseName,
                onChanged: (id, name) {
                  setState(() {
                    currentHouseId = id;
                    currentHouseName = id == 0 ? "Tất cả nhà" : name;
                    selectedRoomName = null;
                  });
                  _updateRoomList(id);
                  ref
                      .read(serviceNotifierProvider(currentHouseId).notifier)
                      .loadServices(houseId: id);
                },
              ),
              CommonFilters.roomFilter(
                context: context,
                rooms: roomsInHouse,
                selectedRoomName: selectedRoomName,
                subtitle: "Lọc dịch vụ theo phòng",
                emptyMessage:
                    "Vui lòng chọn Nhà trọ trước hoặc Nhà chưa có phòng!",
                onChanged: (roomName) {
                  setState(() {
                    selectedRoomName = roomName;
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: servicesAsync.when(
              data: (_) => RefreshIndicator(
                onRefresh: () => ref
                    .read(serviceNotifierProvider(currentHouseId).notifier)
                    .refresh(houseId: currentHouseId),
                color: AppColors.primary,
                child: filteredServices.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: const EmptyStateWidget(
                                icon: Icons.miscellaneous_services_rounded,
                                title: "Chưa có dịch vụ nào",
                                subtitle: "Dữ liệu dịch vụ sẽ hiển thị tại đây",
                              ),
                            ),
                          );
                        },
                      )
                    : _buildListContent(filteredServices),
              ),
              loading: () => const HouseListSkeleton(),
              error: (err, stack) => Center(child: Text("Lỗi: $err")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(List<ServiceModel> services) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: services.length,
      separatorBuilder: (context, index) => const AppListSeparator(),
      itemBuilder: (context, index) => _buildServiceRow(services[index]),
    );
  }

  Widget _buildServiceRow(ServiceModel service) {
    bool isAllHouses = currentHouseId == 0;
    String formattedPrice = CurrencyHelper.formatVND(service.price);
    String cleanUnit = service.unit
        .replaceAll("đ/", "")
        .replaceAll("đ", "")
        .trim();

    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _getServiceIconColor(service.serviceName).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getServiceIcon(service.serviceName),
            color: _getServiceIconColor(service.serviceName),
            size: 22,
          ),
        ),
        title: Text(
          service.serviceName,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Color(0xFF263238),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            isAllHouses
                ? "Áp dụng cho ${service.totalHouses} nhà"
                : "$formattedPrice / $cleanUnit",
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        trailing: isAllHouses
            ? null
            : SizedBox(
                width: 88,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: "Xóa dịch vụ",
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _deleteService(service),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.black12,
                      size: 24,
                    ),
                  ],
                ),
              ),
        onTap: isAllHouses
            ? null
            : () async {
                bool? refresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateServiceScreen(serviceData: service.toJson()),
                  ),
                );
                if (refresh == true) {
                  ref
                      .read(serviceNotifierProvider(currentHouseId).notifier)
                      .refresh(houseId: currentHouseId);
                }
              },
      ),
    );
  }

  IconData _getServiceIcon(String name) {
    name = name.toLowerCase();
    if (name.contains("điện")) return Icons.flash_on_rounded;
    if (name.contains("nước")) return Icons.water_drop_rounded;
    if (name.contains("xe")) return Icons.directions_bike_rounded;
    if (name.contains("wifi") || name.contains("internet")) {
      return Icons.wifi_rounded;
    }
    if (name.contains("vệ sinh") || name.contains("rác")) {
      return Icons.cleaning_services_rounded;
    }
    if (name.contains("quản lý") || name.contains("phí")) {
      return Icons.admin_panel_settings_rounded;
    }
    return Icons.miscellaneous_services_rounded;
  }

  Color _getServiceIconColor(String name) {
    name = name.toLowerCase();
    if (name.contains("điện")) return Colors.orange;
    if (name.contains("nước")) return Colors.blue;
    if (name.contains("xe")) return Colors.green;
    if (name.contains("wifi") || name.contains("internet")) {
      return Colors.indigo;
    }
    if (name.contains("vệ sinh") || name.contains("rác")) return Colors.teal;
    if (name.contains("quản lý") || name.contains("phí")) {
      return Colors.blueGrey;
    }
    return AppColors.primary;
  }
}
