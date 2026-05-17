import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart';
import '../create/create_house_screen.dart';
import '../detail/house_detail_screen.dart';
import '../providers/house_notifier.dart';
import 'widgets/house_list_widgets.dart';
import 'widgets/house_list_skeleton.dart';
import '../providers/house_filter_provider.dart';
import '../providers/manager_provider.dart';

class HouseListScreen extends ConsumerStatefulWidget {
  const HouseListScreen({super.key});

  @override
  ConsumerState<HouseListScreen> createState() => _HouseListScreenState();
}

class _HouseListScreenState extends ConsumerState<HouseListScreen> {
  UserModel? currentUser;
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) setState(() => currentUser = user);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final housesAsync = ref.watch(houseNotifierProvider);
    final houses = ref.watch(filteredHousesListProvider);
    final canCreateHouse =
        currentUser != null && currentUser!.role != 'manager';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'DANH SÁCH KHU TRỌ',
        onBack: () => Navigator.pop(context),
        isSearching: isSearching,
        searchController: _searchController,
        onSearchToggle: () => setState(() {
          isSearching = !isSearching;
          if (!isSearching) {
            _searchController.clear();
            ref.read(houseFilterNotifierProvider.notifier).setSearchQuery("");
          }
        }),
        onSearchChanged: (val) =>
            ref.read(houseFilterNotifierProvider.notifier).setSearchQuery(val),
      ),
      floatingActionButton: canCreateHouse
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () async {
                bool? result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateHouseScreen()),
                );
                if (result == true) {
                  ref.read(houseNotifierProvider.notifier).refresh();
                }
              },
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilters(),
          Expanded(
            child: housesAsync.when(
              data: (_) {
                if (houses.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(houseNotifierProvider.notifier).refresh(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: const EmptyStateWidget(
                              icon: Icons.home_work_outlined,
                              title: "Không tìm thấy khu trọ nào",
                              subtitle:
                                  "Thử thay đổi bộ lọc hoặc tìm kiếm khác",
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(houseNotifierProvider.notifier).refresh(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: houses.length,
                    separatorBuilder: (context, index) =>
                        const AppListSeparator(),
                    itemBuilder: (context, index) => HouseCard(
                      house: houses[index],
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HouseDetailScreen(houseId: houses[index].id),
                          ),
                        );
                        if (result == true) {
                          ref.read(houseNotifierProvider.notifier).refresh();
                        }
                      },
                    ),
                  ),
                );
              },
              loading: () => const HouseListSkeleton(),
              error: (err, stack) => Center(child: Text("Lỗi: $err")),
              skipLoadingOnRefresh: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final allHouses = ref.watch(houseNotifierProvider).value ?? [];
    final allManagers = ref.watch(allManagersProvider).value ?? [];
    final filter = ref.watch(houseFilterNotifierProvider);

    // 1. Lấy danh sách thành phố duy nhất từ dữ liệu hiện có
    final cities = allHouses
        .map((h) => h.city)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    return AppFilterBar(
      pillItems: CommonFilters.houseStatusPills(),
      selectedPillValue: filter.status,
      onPillSelected: (val) =>
          ref.read(houseFilterNotifierProvider.notifier).setStatus(val),
      isEqualWidth: true,
      dropdownItems: [
        CommonFilters.cityFilter(
          context: context,
          cities: cities,
          selectedCity: filter.city,
          onChanged: (val) =>
              ref.read(houseFilterNotifierProvider.notifier).setCity(val),
        ),
        CommonFilters.managerFilter(
          context: context,
          managers: allManagers,
          selectedManager: filter.managerName,
          onChanged: (val) =>
              ref.read(houseFilterNotifierProvider.notifier).setManager(val),
        ),
      ],
    );
  }
}
