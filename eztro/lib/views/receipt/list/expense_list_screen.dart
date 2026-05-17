import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/expense_service.dart';
import '../../../services/house_service.dart';
import '../../../models/house_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_helper.dart';
import '../../../core/utils/receipt_type_helper.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../house/list/widgets/house_list_skeleton.dart';
import '../create/create_expense_screen.dart';
import '../detail/expense_detail_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  int currentHouseId = 0;
  String currentHouseName = "Tất cả nhà";
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  List<HouseModel> houses = [];
  List<dynamic> displayItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final houseData = await HouseService.getHouses();
    if (mounted) setState(() => houses = houseData);
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() => isLoading = true);
    final data = await ExpenseService.getExpenses(
      houseId: currentHouseId,
      month: selectedMonth,
      year: selectedYear,
    );

    if (mounted) {
      setState(() {
        _processGroupedData(data);
        isLoading = false;
      });
    }
  }

  void _processGroupedData(List<Map<String, dynamic>> rawData) {
    displayItems = [];
    if (rawData.isEmpty) return;

    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var e in rawData) {
      String date = e['expense_date'];
      if (!grouped.containsKey(date)) grouped[date] = [];
      grouped[date]!.add(e);
    }

    var sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    for (var date in sortedDates) {
      final list = grouped[date]!;
      double dayTotal = list.fold(
        0,
        (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0),
      );

      displayItems.add({'type': 'header', 'date': date, 'total': dayTotal});
      for (var i = 0; i < list.length; i++) {
        displayItems.add({
          'type': 'item',
          'data': list[i],
          'isLast': i == list.length - 1,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "DANH SÁCH CHI",
        onBack: () => Navigator.pop(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateExpenseScreen()),
          );
          if (res == true) _fetchExpenses();
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
                  _fetchExpenses();
                },
              ),
              CommonFilters.monthYearFilter(
                context: context,
                selectedMonth: selectedMonth,
                selectedYear: selectedYear,
                subtitle: "Lọc phiếu chi theo tháng",
                onChanged: (month, year) {
                  setState(() {
                    selectedMonth = month;
                    selectedYear = year;
                  });
                  _fetchExpenses();
                },
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchExpenses(),
              color: AppColors.primary,
              child: isLoading
                  ? const HouseListSkeleton()
                  : displayItems.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: displayItems.length,
                      itemBuilder: (context, index) {
                        final item = displayItems[index];
                        if (item['type'] == 'header') {
                          return _buildDateHeader(item['date'], item['total']);
                        } else {
                          return _buildMoMoExpenseItem(
                            item['data'],
                            item['isLast'],
                          );
                        }
                      },
                    ),
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

  Widget _buildMoMoExpenseItem(Map<String, dynamic> item, bool isLast) {
    final amount = double.parse(item['amount'].toString());
    final rawType = item['expense_type'];
    final type = ReceiptTypeHelper.toVietnamese(rawType, isReceipt: false);

    // Icon logic based on Vietnamese labels
    IconData iconData = Icons.payments_rounded;
    Color iconColor = Colors.blueGrey;

    final lowerType = type.toLowerCase();
    if (lowerType.contains('sửa') || lowerType.contains('bảo')) {
      iconData = Icons.build_rounded;
      iconColor = Colors.blueGrey;
    } else if (lowerType.contains('điện')) {
      iconData = Icons.flash_on_rounded;
      iconColor = Colors.amber;
    } else if (lowerType.contains('nước')) {
      iconData = Icons.water_drop_rounded;
      iconColor = Colors.cyan;
    } else if (lowerType.contains('trả') || lowerType.contains('cọc')) {
      iconData = Icons.security_rounded;
      iconColor = Colors.orange;
    } else if (lowerType.contains('hủy') || lowerType.contains('hoàn')) {
      iconData = Icons.keyboard_return_rounded;
      iconColor = Colors.red;
    } else {
      iconData = Icons.payments_rounded;
      iconColor = Colors.blueGrey;
    }

    String timeStr = "--:--";
    try {
      final dt = DateTime.parse(item['created_at'] ?? item['expense_date']);
      timeStr = DateFormat('HH:mm').format(dt);
    } catch (_) {}

    return Column(
      children: [
        ListTile(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExpenseDetailScreen(
                expenseId: int.parse(item['id'].toString()),
              ),
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
                  "${item['house_name'] ?? 'Nhà'} - Phòng ${item['room_name'] ?? 'N/A'}",
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
            "-${CurrencyHelper.formatVND(amount)}",
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
      icon: Icons.payments_outlined,
      title: "Không có phiếu chi nào",
      subtitle: "Dữ liệu phiếu chi sẽ hiện tại đây",
    );
  }
}
