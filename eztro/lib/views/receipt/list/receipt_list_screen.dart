import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/house_service.dart';
import '../../../models/house_model.dart';
import '../../../models/receipt_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_helper.dart';
import '../../../core/utils/receipt_type_helper.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../create/create_receipt_screen.dart';
import '../detail/receipt_detail_screen.dart';
import '../../house/list/widgets/house_list_skeleton.dart';
import '../providers/receipt_notifier.dart';

class ReceiptListScreen extends ConsumerStatefulWidget {
  const ReceiptListScreen({super.key});

  @override
  ConsumerState<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends ConsumerState<ReceiptListScreen> {
  int currentHouseId = 0;
  String currentHouseName = "Tất cả nhà";
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  List<HouseModel> houses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final houseData = await HouseService.getHouses();
    if (mounted) setState(() => houses = houseData);
  }

  ReceiptFilter _getCurrentFilter() {
    return ReceiptFilter(
      houseId: currentHouseId,
      month: selectedMonth,
      year: selectedYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = _getCurrentFilter();
    final displayItems = ref.watch(groupedReceiptsProvider(filter));
    final receiptsAsync = ref.watch(receiptNotifierProvider(filter));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "DANH SÁCH THU",
        onBack: () => Navigator.pop(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateReceiptScreen()),
          );
          if (res == true) {
            ref
                .read(receiptNotifierProvider(filter).notifier)
                .refresh(filter: filter);
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
                subtitle: "Lọc phiếu thu theo tháng",
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
            child: receiptsAsync.when(
              data: (_) => RefreshIndicator(
                onRefresh: () => ref
                    .read(receiptNotifierProvider(filter).notifier)
                    .refresh(filter: filter),
                color: AppColors.primary,
                child: displayItems.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          if (item['type'] == 'header') {
                            return _buildDateHeader(
                              item['date'],
                              item['total'],
                            );
                          } else {
                            return _buildMoMoReceiptItem(
                              item['data'],
                              item['isLast'],
                            );
                          }
                        },
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

  Widget _buildDateHeader(String date, double total) {
    String displayDate = date;
    try {
      final dt = DateTime.parse(date);
      displayDate = "Ngày ${DateFormat('dd/MM').format(dt)}";
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            displayDate,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Text(
            "Tổng: ${CurrencyHelper.formatVND(total)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoMoReceiptItem(ReceiptModel item, bool isLast) {
    final amount = item.amount;
    final type = ReceiptTypeHelper.toVietnamese(
      item.receiptType,
      isReceipt: true,
    );

    IconData iconData = Icons.receipt_long_rounded;
    Color iconColor = Colors.blueGrey;

    final lowerType = type.toLowerCase();
    if (lowerType.contains('phòng')) {
      iconData = Icons.home_work_rounded;
      iconColor = Colors.blue;
    } else if (lowerType.contains('cọc')) {
      iconData = Icons.security_rounded;
      iconColor = Colors.orange;
    } else if (lowerType.contains('điện')) {
      iconData = Icons.flash_on_rounded;
      iconColor = Colors.amber;
    } else if (lowerType.contains('nước')) {
      iconData = Icons.water_drop_rounded;
      iconColor = Colors.cyan;
    } else if (lowerType.contains('xe')) {
      iconData = Icons.directions_bike_rounded;
      iconColor = Colors.teal;
    }

    String timeStr = "--:--";
    try {
      final dt = DateTime.parse(item.createdAt ?? item.receiptDate);
      timeStr = DateFormat('HH:mm').format(dt);
    } catch (_) {}

    return Column(
      children: [
        ListTile(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReceiptDetailScreen(receiptId: item.id),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          title: Text(
            type,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF263238),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${item.houseName ?? 'Nhà'} - Phòng ${item.roomName ?? 'N/A'}",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          trailing: Text(
            "+${CurrencyHelper.formatVND(amount)}",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Colors.black,
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              thickness: 1.0,
              color: Colors.black.withOpacity(0.22),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.account_balance_wallet_outlined,
      title: "Không có phiếu thu nào",
      subtitle: "Dữ liệu phiếu thu sẽ hiển thị tại đây",
    );
  }
}
