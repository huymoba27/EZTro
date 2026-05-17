import 'package:eztro/views/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/house_service.dart';
import '../../../models/house_model.dart';
import '../../../models/contract_model.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/contract_notifier.dart';
import '../providers/contract_filter_provider.dart';
import '../create/create_contract_screen.dart';
import '../detail/contract_detail_screen.dart';
import 'widgets/contract_card.dart';
import '../../house/list/widgets/house_list_skeleton.dart';

class ContractListScreen extends ConsumerStatefulWidget {
  const ContractListScreen({super.key});

  @override
  ConsumerState<ContractListScreen> createState() => _ContractListScreenState();
}

class _ContractListScreenState extends ConsumerState<ContractListScreen> {
  List<HouseModel> houses = [];
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHouses() async {
    final houseData = await HouseService.getHouses();
    if (mounted) setState(() => houses = houseData);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isTenant = user?.role == 'tenant';

    final contractsAsync = ref.watch(filteredContractsProvider);
    final filter = ref.watch(contractFilterNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: isTenant ? "HỢP ĐỒNG CỦA TÔI" : "HỢP ĐỒNG",
        showBackButton: true,
        isSearching: !isTenant && isSearching,
        searchController: searchController,
        onSearchToggle: isTenant
            ? null
            : () => setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchController.clear();
                  ref
                      .read(contractFilterNotifierProvider.notifier)
                      .updateQuery("");
                }
              }),
        onSearchChanged: (val) =>
            ref.read(contractFilterNotifierProvider.notifier).updateQuery(val),
      ),
      floatingActionButton: isTenant
          ? null
          : FloatingActionButton(
              onPressed: () async {
                bool? refresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateContractScreen(),
                  ),
                );
                if (refresh == true) {
                  ref.read(contractNotifierProvider.notifier).refresh();
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: Column(
        children: [
          if (!isTenant)
            AppFilterBar(
              selectedPillValue: filter['status'],
              onPillSelected: (val) => ref
                  .read(contractFilterNotifierProvider.notifier)
                  .updateStatus(val),
              pillItems: [
                FilterPillItem(
                  label: "Tất cả",
                  icon: Icons.grid_view_outlined,
                  color: Colors.blue,
                  value: "all",
                ),
                FilterPillItem(
                  label: "Còn hạn",
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  value: "active",
                ),
                FilterPillItem(
                  label: "Hết hạn",
                  icon: Icons.history_toggle_off_outlined,
                  color: Colors.red,
                  value: "expired",
                ),
              ],
              isEqualWidth: true,
              dropdownItems: [
                CommonFilters.houseFilter(
                  context: context,
                  houses: houses,
                  currentHouseId: filter['houseId'],
                  currentHouseName: _getSelectedHouseName(filter['houseId']),
                  showAllOption: true,
                  onChanged: (id, name) => ref
                      .read(contractFilterNotifierProvider.notifier)
                      .updateHouse(id),
                ),
              ],
            ),
          Expanded(
            child: contractsAsync.when(
              data: (contracts) => RefreshIndicator(
                onRefresh: () =>
                    ref.read(contractNotifierProvider.notifier).refresh(),
                color: AppColors.primary,
                child: contracts.isEmpty
                    ? _buildEmptyState()
                    : _buildListContent(contracts),
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
              icon: Icons.description_outlined,
              title: "Không có hợp đồng nào",
              subtitle: "Vui lòng kiểm tra lại hoặc tạo mới",
            ),
          ),
        );
      },
    );
  }

  Widget _buildListContent(List<ContractModel> contracts) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: contracts.length,
      separatorBuilder: (context, index) =>
          Container(height: 10, color: const Color(0xFFF2F2F7)),
      itemBuilder: (context, index) {
        final contract = contracts[index];
        return ContractCard(
          contract: contract,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContractDetailScreen(contract: contract),
              ),
            );
            if (result == true) {
              ref.read(contractNotifierProvider.notifier).refresh();
            }
          },
        );
      },
    );
  }

  String _getSelectedHouseName(int houseId) {
    if (houseId == 0) return "Tất cả nhà";
    try {
      return houses.firstWhere((h) => h.id == houseId).houseName;
    } catch (_) {
      return "Chọn nhà";
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return "Còn hạn";
      case 'expired':
        return "Hết hạn";
      default:
        return "Tất cả trạng thái";
    }
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text(
                      "TRẠNG THÁI HỢP ĐỒNG",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Lọc danh sách theo trạng thái",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _statusOption("Tất cả trạng thái", "all"),
              _statusOption("Còn hạn", "active"),
              _statusOption("Hết hạn", "expired"),
            ],
          ),
        );
      },
    );
  }

  Widget _statusOption(String label, String value) {
    final currentStatus = ref.watch(contractFilterNotifierProvider)['status'];
    final isSelected = currentStatus == value;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        ref.read(contractFilterNotifierProvider.notifier).updateStatus(value);
        Navigator.pop(context);
      },
    );
  }
}
