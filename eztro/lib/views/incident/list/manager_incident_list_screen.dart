import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/incident_model.dart';
import '../../../models/house_model.dart';
import '../../../core/constants/app_colors.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../services/house_service.dart';
import '../widgets/incident_card.dart';
import '../providers/incident_notifier.dart';
import '../providers/incident_filter_provider.dart';

class ManagerIncidentListScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackToHome;
  const ManagerIncidentListScreen({super.key, this.onBackToHome});

  @override
  ConsumerState<ManagerIncidentListScreen> createState() =>
      _ManagerIncidentListScreenState();
}

class _ManagerIncidentListScreenState
    extends ConsumerState<ManagerIncidentListScreen> {
  final int _currentHouseId = 0;
  final String _currentHouseName = "Tất cả nhà";
  List<HouseModel> _houses = [];

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  Future<void> _loadHouses() async {
    try {
      final houses = await HouseService.getHouses();
      if (mounted) {
        setState(() {
          _houses = houses;
        });
      }
    } catch (e) {
      debugPrint("Error loading houses: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(incidentFilterNotifierProvider);
    final incidentsAsync = ref.watch(filteredIncidentsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "QUẢN LÝ SỰ CỐ",
        showBackButton: true,
        onBack: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            widget.onBackToHome?.call();
          }
        },
      ),
      body: Column(
        children: [
          AppFilterBar(
            pillItems: _getPillItems(),
            selectedPillValue: filter.status,
            onPillSelected: (val) => ref
                .read(incidentFilterNotifierProvider.notifier)
                .setStatus(val),
            isEqualWidth: true,
            dropdownItems: [
              CommonFilters.houseFilter(
                context: context,
                houses: _houses,
                currentHouseId: filter.houseId ?? 0,
                currentHouseName: filter.houseName ?? "Tất cả nhà",
                onChanged: (id, name) {
                  ref
                      .read(incidentFilterNotifierProvider.notifier)
                      .setHouse(id == 0 ? null : id, id == 0 ? null : name);
                },
              ),
              DropdownFilterItem(
                icon: Icons.meeting_room_outlined,
                label: "Phòng",
                onTap: () {
                  // Logic chọn phòng nếu cần
                },
              ),
            ],
          ),
          Expanded(
            child: incidentsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => Center(child: Text("Lỗi: $err")),
              data: (incidents) => _buildIncidentList(incidents),
            ),
          ),
        ],
      ),
    );
  }

  List<FilterPillItem> _getPillItems() {
    return [
      FilterPillItem(
        label: "Tất cả",
        icon: Icons.grid_view_rounded,
        value: "all",
        color: Colors.blue,
      ),
      FilterPillItem(
        label: "Mới gửi",
        icon: Icons.fiber_new_rounded,
        value: "pending",
        color: Colors.orange,
      ),
      FilterPillItem(
        label: "Đang xử lý",
        icon: Icons.build_circle_outlined,
        value: "processing",
        color: Colors.blue,
      ),
      FilterPillItem(
        label: "Đã xong",
        icon: Icons.check_circle_outline_rounded,
        value: "resolved",
        color: Colors.green,
      ),
    ];
  }

  Widget _buildIncidentList(List<IncidentModel> incidents) {
    if (incidents.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(incidentNotifierProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const EmptyStateWidget(
              icon: Icons.assignment_turned_in_rounded,
              title: "Không có sự cố nào",
              subtitle:
                  "Các sự cố sẽ hiển thị theo trạng thái và bộ lọc tương ứng",
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(incidentNotifierProvider.notifier).refresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: incidents.length,
        itemBuilder: (context, index) {
          final item = incidents[index];
          return IncidentCard(incident: item);
        },
      ),
    );
  }
}
