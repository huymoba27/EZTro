class StatisticsModel {
  final StatsSummary summary;
  final List<double> revenueChart;
  final List<double> expenseChart;

  StatisticsModel({
    required this.summary,
    required this.revenueChart,
    required this.expenseChart,
  });

  factory StatisticsModel.fromJson(Map<String, dynamic> json) {
    return StatisticsModel(
      summary: StatsSummary.fromJson(json['summary'] ?? {}),
      revenueChart: (json['revenue_chart'] as List?)?.map((e) => double.parse(e.toString())).toList() ?? List.filled(12, 0.0),
      expenseChart: (json['expense_chart'] as List?)?.map((e) => double.parse(e.toString())).toList() ?? List.filled(12, 0.0),
    );
  }
}

class StatsSummary {
  final int totalHouses;
  final int totalRooms;
  final int occupiedRooms;
  final double totalRevenue;
  final double totalExpense;
  final double netProfit;

  StatsSummary({
    required this.totalHouses,
    required this.totalRooms,
    required this.occupiedRooms,
    required this.totalRevenue,
    required this.totalExpense,
    required this.netProfit,
  });

  factory StatsSummary.fromJson(Map<String, dynamic> json) {
    return StatsSummary(
      totalHouses: int.tryParse(json['total_houses']?.toString() ?? '0') ?? 0,
      totalRooms: int.tryParse(json['total_rooms']?.toString() ?? '0') ?? 0,
      occupiedRooms: int.tryParse(json['occupied_rooms']?.toString() ?? '0') ?? 0,
      totalRevenue: double.tryParse(json['total_revenue']?.toString() ?? '0') ?? 0.0,
      totalExpense: double.tryParse(json['total_expense']?.toString() ?? '0') ?? 0.0,
      netProfit: double.tryParse(json['net_profit']?.toString() ?? '0') ?? 0.0,
    );
  }
}
