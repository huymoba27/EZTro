class ReceiptModel {
  final int id;
  final int houseId;
  final int roomId;
  final String? houseName;
  final String? roomName;
  final double amount;
  final String receiptDate;
  final String receiptType;
  final String? description;
  final String? createdAt;

  ReceiptModel({
    required this.id,
    required this.houseId,
    required this.roomId,
    this.houseName,
    this.roomName,
    required this.amount,
    required this.receiptDate,
    required this.receiptType,
    this.description,
    this.createdAt,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: int.tryParse(json['id']?.toString() ?? "0") ?? 0,
      houseId: int.tryParse(json['house_id']?.toString() ?? "0") ?? 0,
      roomId: int.tryParse(json['room_id']?.toString() ?? "0") ?? 0,
      houseName: json['house_name']?.toString(),
      roomName: json['room_name']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? "0") ?? 0,
      receiptDate: json['receipt_date']?.toString() ?? "",
      receiptType: json['receipt_type']?.toString() ?? "other",
      description: json['description']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'house_id': houseId,
      'room_id': roomId,
      'house_name': houseName,
      'room_name': roomName,
      'amount': amount,
      'receipt_date': receiptDate,
      'receipt_type': receiptType,
      'description': description,
      'created_at': createdAt,
    };
  }
}
