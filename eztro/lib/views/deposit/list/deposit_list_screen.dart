import 'package:eztro/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/format_helper.dart';
import '../../../services/house_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/house_model.dart';
import '../../../models/user_model.dart';
import '../../../models/deposit_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../house/list/widgets/house_list_skeleton.dart';
import '../create/create_deposit_screen.dart';
import '../detail/deposit_detail_screen.dart';
import '../providers/deposit_notifier.dart';

class DepositListScreen extends ConsumerStatefulWidget {
  const DepositListScreen({super.key});

  @override
  ConsumerState<DepositListScreen> createState() => _DepositListScreenState();
}

class _DepositListScreenState extends ConsumerState<DepositListScreen> {
  int currentHouseId = 0;
  String currentHouseName = "Tất cả nhà";
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  String selectedStatus = "all";
  List<HouseModel> houses = [];
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = await AuthService.getCurrentUser();
    final houseData = await HouseService.getHouses();
    if (mounted) {
      setState(() {
        currentUser = user;
        houses = houseData;
      });
    }
  }

  DepositFilter _getCurrentFilter() {
    return DepositFilter(
      houseId: currentHouseId,
      month: selectedMonth,
      year: selectedYear,
      userId: currentUser?.id ?? 0,
      role: currentUser?.role ?? "landlord",
      status: selectedStatus == "all" ? "" : selectedStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = _getCurrentFilter();
    final depositsAsync = currentUser == null
        ? const AsyncValue<List<DepositModel>>.loading()
        : ref.watch(depositNotifierProvider(filter));

    final filteredDeposits = currentUser == null
        ? <DepositModel>[]
        : ref.watch(filteredDepositsProvider(filter));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "DANH SÁCH ĐẶT CỌC",
        onBack: () => Navigator.pop(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateDepositScreen()),
          );
          if (res == true) {
            ref
                .read(depositNotifierProvider(filter).notifier)
                .refresh(filter: filter);
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
                label: "Chờ lập HĐ",
                icon: Icons.pending_actions,
                color: Colors.orange,
                value: "pending",
              ),
              FilterPillItem(
                label: "Đã thuê",
                icon: Icons.check_circle_outline,
                color: Colors.green,
                value: "completed",
              ),
              FilterPillItem(
                label: "Đã hủy",
                icon: Icons.cancel_outlined,
                color: Colors.red,
                value: "cancelled",
              ),
            ],
            isEqualWidth: true,
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
                  });
                },
              ),
              CommonFilters.monthYearFilter(
                context: context,
                selectedMonth: selectedMonth,
                selectedYear: selectedYear,
                subtitle: "Lọc tiền cọc theo tháng",
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
            child: depositsAsync.when(
              data: (_) => RefreshIndicator(
                onRefresh: () => ref
                    .read(depositNotifierProvider(filter).notifier)
                    .refresh(filter: filter),
                color: AppColors.primary,
                child: Container(
                  color: Colors.white,
                  child: filteredDeposits.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: filteredDeposits.length,
                          separatorBuilder: (context, index) =>
                              _buildListDivider(),
                          itemBuilder: (context, index) => _buildDepositCard(
                            filteredDeposits[index],
                            filter,
                          ),
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
    return const EmptyStateWidget(
      icon: Icons.security_rounded,
      title: "Không có dữ liệu đặt cọc",
      subtitle: "Dữ liệu tiền cọc sẽ hiển thị tại đây",
    );
  }

  Widget _buildDepositCard(DepositModel item, DepositFilter filter) {
    String status = item.status.toLowerCase();
    Color statusColor = Colors.orange;
    String statusText = "CHỜ XỬ LÝ";

    if (status == 'waiting_payment') {
      statusColor = Colors.orange;
      statusText = "CHỜ THANH TOÁN";
    } else if (status == 'pending') {
      statusColor = Colors.blue;
      statusText = "CHỜ LẬP HĐ";
    } else if (status == 'confirmed' || status == 'completed') {
      statusColor = const Color(0xFF2E7D32);
      statusText = "ĐÃ THUÊ";
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
      statusText = "ĐÃ HỦY";
    } else if (status == 'expired') {
      statusColor = Colors.grey;
      statusText = "HẾT HẠN";
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final refresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DepositDetailScreen(depositId: item.id),
                  ),
                );
                if (refresh == true) {
                  ref
                      .read(depositNotifierProvider(filter).notifier)
                      .refresh(filter: filter);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Text(
                            "Phòng ${item.roomName}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF263238),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 32),
                        const Expanded(
                          flex: 4,
                          child: Text(
                            "Dự kiến vào:",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- CỘT TRÁI ---
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(26),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusText.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CardInfoRow(
                                  icon: Icons.person_outline,
                                  text: item.customerName ?? "Trống",
                                  textColor: Colors.black,
                                ),
                                const SizedBox(height: 8),
                                CardInfoRow(
                                  icon: Icons.home_outlined,
                                  text: item.houseName ?? "N/A",
                                ),
                                const SizedBox(height: 8),
                                CardInfoRow(
                                  icon: Icons.monetization_on_outlined,
                                  text: CurrencyHelper.formatVND(item.depositAmount),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          // --- CỘT PHẢI ---
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  item.expectedMoveInDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text("Ngày đặt:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.depositDate,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListDivider() {
    return Container(
      height: 8,
      width: double.infinity,
      color: const Color(0xFFF2F2F7),
    );
  }
}
