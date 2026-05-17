class MeterModel {
  final int? id;
  final int contractId;
  final int roomId;
  final int userId;
  final String readingDate;
  final int billingMonth;
  final int billingYear;
  
  final int oldElectric;
  final int newElectric;
  final int oldWater;
  final int newWater;

  MeterModel({
    this.id,
    required this.contractId,
    required this.roomId,
    required this.userId, 
    required this.readingDate,
    required this.billingMonth,
    required this.billingYear,
    required this.oldElectric,
    required this.newElectric,
    required this.oldWater,
    required this.newWater,
  });

  int get electricUsage => newElectric - oldElectric;
  int get waterUsage => newWater - oldWater;

  factory MeterModel.fromJson(Map<String, dynamic> json) {
    return MeterModel(
      id: int.tryParse(json['id'].toString()),
      contractId: int.parse(json['contract_id'].toString()),
      roomId: int.parse(json['room_id'].toString()),
      userId: int.tryParse(json['user_id']?.toString() ?? '1') ?? 1,
      readingDate: json['reading_date'] ?? "",
      billingMonth: int.parse(json['billing_month'].toString()),
      billingYear: int.parse(json['billing_year'].toString()),
      oldElectric: int.parse(json['old_electric'].toString()),
      newElectric: int.parse(json['new_electric'].toString()),
      oldWater: int.parse(json['old_water'].toString()),
      newWater: int.parse(json['new_water'].toString()),
    );
  }

  Map<String, String> toJson() {
    return {
      "contract_id": contractId.toString(),
      "room_id": roomId.toString(),
      "user_id": userId.toString(),
      "old_e": oldElectric.toString(),
      "new_e": newElectric.toString(),
      "old_w": oldWater.toString(),
      "new_w": newWater.toString(),
      "month": billingMonth.toString(),
      "year": billingYear.toString(),
    };
  }
}