import 'package:eztro/views/house/list/widgets/house_list_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/meter_service.dart';
import '../../../services/house_service.dart';
import '../../../models/house_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../core/utils/dialog_helper.dart';
import 'widgets/meter_list_body.dart';
import 'package:eztro/views/meter/detail/meter_detail_screen.dart';
import 'package:eztro/views/meter/create/create_meter_screen.dart';
import '../providers/meter_notifier.dart';

class MeterReadingScreen extends ConsumerStatefulWidget {
  const MeterReadingScreen({super.key});

  @override
  ConsumerState<MeterReadingScreen> createState() => _MeterReadingScreenState();
}

class _MeterReadingScreenState extends ConsumerState<MeterReadingScreen> {
  final Color themeGreen = AppColors.primary;
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  int selectedHouseId = 0;
  String selectedStatus = "all"; // all, recorded, pending
  List<HouseModel> allHouses = [];
  String userRole = 'landlord';

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
    final user = await AuthService.getCurrentUser();
    final houses = await HouseService.getHouses();
    if (mounted) {
      setState(() {
        userRole = user?.role ?? 'landlord';
        allHouses = houses;
      });
    }
  }

  MeterFilter _getCurrentFilter() {
    return MeterFilter(
      houseId: selectedHouseId,
      month: selectedMonth,
      year: selectedYear,
      status: selectedStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = _getCurrentFilter();
    final filteredList = ref.watch(filteredMeterDataProvider(filter));
    final meterAsync = ref.watch(meterNotifierProvider(filter));
    final currentHouse = allHouses.firstWhere(
      (h) => h.id == selectedHouseId,
      orElse: () => HouseModel(
        id: 0,
        houseName: "Tất cả nhà",
        image: "",
        status: "",
        city: "",
        ward: "",
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'ĐIỆN NƯỚC',
        showBackButton: true,
        onBack: () => Navigator.pop(context),
        isSearching: isSearching,
        searchController: searchController,
        onSearchChanged: (v) =>
            ref.read(meterSearchProvider.notifier).state = v,
        onSearchToggle: () => setState(() {
          isSearching = !isSearching;
          if (!isSearching) {
            searchController.clear();
            ref.read(meterSearchProvider.notifier).state = "";
          }
        }),
      ),
      floatingActionButton: userRole == 'tenant'
          ? null
          : FloatingActionButton(
              onPressed: () async {
                bool? refresh = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateMeterScreen()),
                );
                if (refresh == true) {
                  ref
                      .read(meterNotifierProvider(filter).notifier)
                      .refresh(filter: filter);
                }
              },
              backgroundColor: AppColors.primary,
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
      body: Column(
        children: [
          AppFilterBar(
            selectedPillValue: selectedStatus,
            onPillSelected: (val) => setState(() => selectedStatus = val),
            pillItems: [
              FilterPillItem(
                label: "Tất cả",
                icon: Icons.grid_view_outlined,
                color: Colors.blue,
                value: "all",
              ),
              FilterPillItem(
                label: "Đã chốt",
                icon: Icons.check_circle_outline,
                color: Colors.green,
                value: "recorded",
              ),
              FilterPillItem(
                label: "Chưa chốt",
                icon: Icons.pending_actions,
                color: Colors.orange,
                value: "pending",
              ),
            ],
            isEqualWidth: true,
            dropdownItems: [
              CommonFilters.houseFilter(
                context: context,
                houses: allHouses,
                currentHouseId: selectedHouseId,
                currentHouseName: currentHouse.houseName,
                showAllOption: true,
                onChanged: (id, name) {
                  setState(() => selectedHouseId = id);
                },
              ),
              CommonFilters.monthYearFilter(
                context: context,
                selectedMonth: selectedMonth,
                selectedYear: selectedYear,
                subtitle: "Lọc chỉ số điện nước",
                onChanged: (month, year) {
                  setState(() {
                    selectedMonth = month;
                    selectedYear = year;
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: meterAsync.when(
              data: (_) => RefreshIndicator(
                onRefresh: () => ref
                    .read(meterNotifierProvider(filter).notifier)
                    .refresh(filter: filter),
                color: AppColors.primary,
                child: Container(
                  color: Colors.white,
                  child: filteredList.isEmpty
                      ? _buildEmptyState()
                      : MeterListBody(
                          filteredList: filteredList,
                          themeGreen: themeGreen,
                          month: selectedMonth,
                          year: selectedYear,
                          onTapRoom: (room) async {
                            bool isRecorded =
                                (room['id'] != null &&
                                room['id'].toString() != '0');
                            if (!isRecorded) {
                              if (userRole == 'tenant') return;
                              bool? refresh = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CreateMeterScreen(meterData: room),
                                ),
                              );
                              if (refresh == true) {
                                ref
                                    .read(
                                      meterNotifierProvider(filter).notifier,
                                    )
                                    .refresh(filter: filter);
                              }
                            } else {
                              _showDetailModal(room, filter);
                            }
                          },
                        ),
                ),
              ),
              loading: () => const HouseListSkeleton(),
              error: (err, stack) => Center(child: Text("Lỗi: $err")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const EmptyStateWidget(
              icon: Icons.bolt_outlined,
              title: "Không có dữ liệu chốt số",
              subtitle: "Dữ liệu điện nước sẽ hiển thị tại đây",
            ),
          ),
        );
      },
    );
  }

  void _showDetailModal(dynamic room, MeterFilter filter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeterDetailScreen(
          room: room,
          month: selectedMonth,
          year: selectedYear,
          userRole: userRole,
          onEdit: () async {
            Navigator.pop(context);
            bool? refresh = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateMeterScreen(meterData: room),
              ),
            );
            if (refresh == true) {
              ref
                  .read(meterNotifierProvider(filter).notifier)
                  .refresh(filter: filter);
            }
          },
          onDelete: () {
            _confirmDelete(room, filter);
          },
        ),
      ),
    );
  }

  void _confirmDelete(dynamic room, MeterFilter filter) {
    DialogHelper.showConfirmDialog(
      context: context,
      title: "Xác nhận xóa",
      message: "Dữ liệu chốt số của ${room['room_name']} sẽ bị xóa vĩnh viễn.",
      onConfirm: () async {
        final notifier = ref.read(meterNotifierProvider(filter).notifier);
        try {
          final res = await MeterService.deleteMeterReading(
            int.parse(room['id'].toString()),
          );
          if (res['status'] == 'success') {
            notifier.refresh(filter: filter);
            if (mounted) {
              Navigator.of(context).pop();
              DialogHelper.showSuccess(
                context,
                "Đã xóa chốt số thành công!",
              );
            }
          } else {
            if (mounted) {
              DialogHelper.showError(
                context,
                res['message'] ?? "Không thể xóa chốt số.",
              );
            }
          }
        } catch (e) {
          if (mounted) {
            DialogHelper.showError(context, "Lỗi kết nối: $e");
          }
        }
      },
    );
  }
}
