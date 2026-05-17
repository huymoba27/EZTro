class DepositModel {
  final int id;
  final int houseId;
  final int roomId;
  final String customerName;
  final String customerPhone;
  final double depositAmount;
  final String depositDate;
  final String expectedMoveInDate;
  final String status;
  final String? note;
  final String? houseName;
  final String? roomName;
  final String? createdAt;
  final String? checkoutUrl;
  final String? paymentExpiresAt;
  final String? qrCode;
  final String? bankBin;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? paymentDescription;
  final List<DepositLogModel> logs;

  DepositModel({
    required this.id,
    required this.houseId,
    required this.roomId,
    required this.customerName,
    required this.customerPhone,
    required this.depositAmount,
    required this.depositDate,
    required this.expectedMoveInDate,
    required this.status,
    this.note,
    this.houseName,
    this.roomName,
    this.createdAt,
    this.checkoutUrl,
    this.paymentExpiresAt,
    this.qrCode,
    this.bankBin,
    this.bankAccountNumber,
    this.bankAccountName,
    this.paymentDescription,
    this.logs = const [],
  });

  factory DepositModel.fromJson(Map<String, dynamic> json) {
    return DepositModel(
      id: int.tryParse(json['id']?.toString() ?? "0") ?? 0,
      houseId: int.tryParse(json['house_id']?.toString() ?? "0") ?? 0,
      roomId: int.tryParse(json['room_id']?.toString() ?? "0") ?? 0,
      customerName: json['customer_name']?.toString() ?? "",
      customerPhone: json['customer_phone']?.toString() ?? "",
      depositAmount:
          double.tryParse(json['deposit_amount']?.toString() ?? "0") ?? 0,
      depositDate: json['deposit_date']?.toString() ?? "",
      expectedMoveInDate: json['expected_move_in_date']?.toString() ?? "",
      status: json['status']?.toString() ?? "pending",
      note: json['note']?.toString(),
      houseName: json['house_name']?.toString(),
      roomName: json['room_name']?.toString(),
      createdAt: json['created_at']?.toString(),
      checkoutUrl: json['checkout_url']?.toString(),
      paymentExpiresAt: json['payment_expires_at']?.toString(),
      qrCode: json['qr_code']?.toString(),
      bankBin: json['bank_bin']?.toString(),
      bankAccountNumber: json['bank_account_number']?.toString(),
      bankAccountName: json['bank_account_name']?.toString(),
      paymentDescription: json['payment_description']?.toString(),
      logs: json['logs'] != null
          ? (json['logs'] as List)
              .map((i) => DepositLogModel.fromJson(i))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'house_id': houseId,
      'room_id': roomId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'deposit_amount': depositAmount,
      'deposit_date': depositDate,
      'expected_move_in_date': expectedMoveInDate,
      'status': status,
      'note': note,
      'house_name': houseName,
      'room_name': roomName,
      'created_at': createdAt,
      'checkout_url': checkoutUrl,
      'payment_expires_at': paymentExpiresAt,
      'qr_code': qrCode,
      'bank_bin': bankBin,
      'bank_account_number': bankAccountNumber,
      'bank_account_name': bankAccountName,
      'payment_description': paymentDescription,
      'logs': logs.map((e) => e.toJson()).toList(),
    };
  }
}

class DepositLogModel {
  final int id;
  final String userName;
  final String userRole;
  final String oldStatus;
  final String newStatus;
  final String? reason;
  final String createdAt;

  DepositLogModel({
    required this.id,
    required this.userName,
    required this.userRole,
    required this.oldStatus,
    required this.newStatus,
    this.reason,
    required this.createdAt,
  });

  factory DepositLogModel.fromJson(Map<String, dynamic> json) {
    return DepositLogModel(
      id: int.parse(json['id']?.toString() ?? '0'),
      userName: json['user_name']?.toString() ?? 'N/A',
      userRole: json['user_role']?.toString() ?? 'landlord',
      oldStatus: json['old_status']?.toString() ?? '',
      newStatus: json['new_status']?.toString() ?? '',
      reason: json['reason']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'user_role': userRole,
      'old_status': oldStatus,
      'new_status': newStatus,
      'reason': reason,
      'created_at': createdAt,
    };
  }
}
