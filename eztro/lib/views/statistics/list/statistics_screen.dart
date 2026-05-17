import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/format_helper.dart';
import '../../../core/constants/app_colors.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../models/house_model.dart';
import '../../../services/house_service.dart';
import '../../../models/statistics_model.dart';
import '../providers/statistics_notifier.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int currentHouseId = 0;
  String currentHouseName = "Tất cả nhà";
  List<HouseModel> houses = [];

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  Future<void> _loadHouses() async {
    final houseData = await HouseService.getHouses();
    if (mounted) setState(() => houses = houseData);
  }

  void _showHouseSelection() {
    AppSelectModal.show<int>(
      context: context,
      title: "CHỌN NHÀ TRỌ",
      subtitle: "Lọc dữ liệu theo nhà trọ",
      items: [
        AppSelectItem(label: "Tất cả nhà", value: 0),
        ...houses.map((h) => AppSelectItem(label: h.houseName, value: h.id)),
      ],
      initialValues: [currentHouseId],
      onSelect: (values) {
        if (values.isNotEmpty) {
          setState(() {
            currentHouseId = values.first;
            final found = houses.firstWhere(
              (h) => h.id == values.first,
              orElse: () => HouseModel(
                id: 0,
                houseName: "Tất cả nhà",
                addressDetail: "",
                city: "",
                ward: "",
                totalRooms: 0,
                totalTenants: 0,
                image: "",
                status: "active",
              ),
            );
            currentHouseName = found.houseName;
          });
        }
      },
    );
  }

  void _selectYear() {
    final notifier = ref.read(statisticsProvider(currentHouseId).notifier);
    final years = List.generate(5, (i) => (DateTime.now().year - i).toString());

    AppSelectModal.show<String>(
      context: context,
      title: "CHỌN NĂM",
      subtitle: "Xem thống kê theo năm",
      searchable: false,
      items: years
          .map((y) => AppSelectItem(label: "Năm $y", value: y))
          .toList(),
      initialValues: [notifier.currentYear.toString()],
      onSelect: (values) {
        if (values.isNotEmpty) {
          notifier.changeYear(int.parse(values.first));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statisticsProvider(currentHouseId));
    final currentYear = ref
        .watch(statisticsProvider(currentHouseId).notifier)
        .currentYear;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // Ultra light gray background
      appBar: CustomAppBar(
        title: "BÁO CÁO THỐNG KÊ",
        showBackButton: true,
        onBack: () => Navigator.pop(context),
      ),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(child: Text("Lỗi: $err")),
        data: (stats) => RefreshIndicator(
          onRefresh: () async =>
              ref.read(statisticsProvider(currentHouseId).notifier).loadStats(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- FLAT OVERVIEW SECTION ---
                _buildFlatOverview(stats.summary),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildFlatFilters(currentYear),

                      const SizedBox(height: 32),
                      _buildSectionTitle("HIỆU SUẤT VẬN HÀNH"),
                      const SizedBox(height: 16),
                      _buildOperationGrid(stats.summary),

                      const SizedBox(height: 32),
                      _buildSectionTitle("DOANH THU & CHI PHÍ"),
                      const SizedBox(height: 16),
                      _buildRevenueChart(stats),

                      const SizedBox(height: 32),
                      _buildSectionTitle("TỶ LỆ LẤP ĐẦY"),
                      const SizedBox(height: 16),
                      _buildOccupancyChart(stats.summary),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlatOverview(StatsSummary summary) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "LỢI NHUẬN RÒNG DỰ KIẾN",
            style: TextStyle(
              color: Colors.black45,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyHelper.formatVND(summary.netProfit),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _flatFinanceItem(
                  "TỔNG THU",
                  summary.totalRevenue,
                  const Color(0xFFE3F2FD),
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _flatFinanceItem(
                  "TỔNG CHI",
                  summary.totalExpense,
                  const Color(0xFFFEEBEE),
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flatFinanceItem(String label, double value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyHelper.formatVND(value),
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFlatFilters(int year) {
    return Row(
      children: [
        Expanded(
          child: _flatFilterButton(
            label: currentHouseName,
            icon: Icons.home_work_outlined,
            onTap: _showHouseSelection,
          ),
        ),
        const SizedBox(width: 12),
        _flatFilterButton(
          label: "$year",
          icon: Icons.calendar_today_outlined,
          onTap: _selectYear,
        ),
      ],
    );
  }

  Widget _flatFilterButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.black38),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black26,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationGrid(StatsSummary summary) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: [
        _flatGridItem(
          "TỔNG NHÀ",
          "${summary.totalHouses}",
          Icons.domain_rounded,
          const Color(0xFF6366F1), // Indigo
        ),
        _flatGridItem(
          "TỔNG PHÒNG",
          "${summary.totalRooms}",
          Icons.meeting_room_rounded,
          const Color(0xFFF59E0B), // Amber
        ),
        _flatGridItem(
          "ĐANG Ở",
          "${summary.occupiedRooms}",
          Icons.people_alt_rounded,
          const Color(0xFF10B981), // Emerald
        ),
        _flatGridItem(
          "CÒN TRỐNG",
          "${summary.totalRooms - summary.occupiedRooms}",
          Icons.door_front_door_rounded,
          const Color(0xFFEF4444), // Red
        ),
      ],
    );
  }

  Widget _flatGridItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        // No heavy border, just a very light shadow or background
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black38,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(StatisticsModel stats) {
    return Container(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _chartLegend("Thu", AppColors.primary),
              const SizedBox(width: 16),
              _chartLegend("Chi", const Color(0xFFE2E8F0)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(stats.revenueChart, stats.expenseChart),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black.withOpacity(0.8),
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        "${rodIndex == 0 ? 'Thu' : 'Chi'}\n",
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        children: [
                          TextSpan(
                            text: CurrencyHelper.formatVND(rod.toY),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        const months = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
                        if (value.toInt() < 0 || value.toInt() >= 12) return const SizedBox();
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            months[value.toInt()],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(12, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: stats.revenueChart[i],
                        color: AppColors.primary,
                        width: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      BarChartRodData(
                        toY: stats.expenseChart[i],
                        color: const Color(0xFFF1F5F9),
                        width: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black45,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  double _getMaxY(List<double> d1, List<double> d2) {
    double max = 0;
    for (var v in d1) { if (v > max) max = v; }
    for (var v in d2) { if (v > max) max = v; }
    return max == 0 ? 100 : max * 1.2;
  }

  Widget _buildOccupancyChart(StatsSummary summary) {
    final total = summary.totalRooms.toDouble();
    final occupied = summary.occupiedRooms.toDouble();
    final empty = total - occupied;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 38,
                sections: [
                  PieChartSectionData(
                    value: occupied > 0 ? occupied : 0.1,
                    color: AppColors.primary,
                    radius: 14,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: empty > 0 ? empty : 0.1,
                    color: const Color(0xFFF1F5F9),
                    radius: 14,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _flatLegendItem("Đang ở", AppColors.primary, occupied, total),
                const SizedBox(height: 20),
                _flatLegendItem(
                  "Còn trống",
                  const Color(0xFFCBD5E1),
                  empty,
                  total,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _flatLegendItem(String label, Color color, double value, double total) {
    int percent = total > 0 ? ((value / total) * 100).toInt() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            "$percent% • ${value.toInt()} phòng",
            style: const TextStyle(
              color: Colors.black38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
