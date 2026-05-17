class InvoiceModel {
  final int id;
  final String status;
  final String createdAt;
  final String? houseName;
  final int? houseId;
  final String roomName;
  final int? roomId;
  final int billingMonth;
  final int billingYear;
  final double roomAmount;
  final double serviceAmount;
  final double totalAmount;
  final List<InvoiceDetailModel> details;
  final List<InvoiceLogModel> logs;

  InvoiceModel({
    required this.id,
    required this.status,
    required this.createdAt,
    this.houseName,
    this.houseId,
    required this.roomName,
    this.roomId,
    required this.billingMonth,
    required this.billingYear,
    required this.roomAmount,
    required this.serviceAmount,
    required this.totalAmount,
    required this.details,
    this.logs = const [],
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: int.parse(json['id']?.toString() ?? '0'),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString() ?? '',
      houseName: json['house_name']?.toString(),
      houseId: int.tryParse(json['house_id']?.toString() ?? ''),
      roomName: json['room_name']?.toString() ?? '',
      roomId: int.tryParse(json['room_id']?.toString() ?? ''),
      billingMonth: int.parse(json['billing_month']?.toString() ?? '0'),
      billingYear: int.parse(json['billing_year']?.toString() ?? '0'),
      roomAmount: double.tryParse(json['room_amount']?.toString() ?? '0') ?? 0,
      serviceAmount: double.tryParse(json['service_amount']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      details: json['details'] != null
          ? (json['details'] as List)
              .map((i) => InvoiceDetailModel.fromJson(i))
              .toList()
          : [],
      logs: json['logs'] != null
          ? (json['logs'] as List)
              .map((i) => InvoiceLogModel.fromJson(i))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'created_at': createdAt,
      'house_name': houseName,
      'house_id': houseId,
      'room_name': roomName,
      'room_id': roomId,
      'billing_month': billingMonth,
      'billing_year': billingYear,
      'room_amount': roomAmount,
      'service_amount': serviceAmount,
      'total_amount': totalAmount,
      'details': details.map((e) => e.toJson()).toList(),
      'logs': logs.map((e) => e.toJson()).toList(),
    };
  }
}

class InvoiceDetailModel {
  final String name;
  final double subtotal;
  final double? unitPrice;
  final double? quantity;
  final String? unit;

  InvoiceDetailModel({
    required this.name,
    required this.subtotal,
    this.unitPrice,
    this.quantity,
    this.unit,
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailModel(
      name: json['name']?.toString() ?? 'Dịch vụ',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0'),
      quantity: double.tryParse(json['quantity']?.toString() ?? '0'),
      unit: json['unit']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subtotal': subtotal,
      'unit_price': unitPrice,
      'quantity': quantity,
      'unit': unit,
    };
  }
}

class InvoiceLogModel {
  final int id;
  final String userName;
  final String userRole;
  final String oldStatus;
  final String newStatus;
  final String? reason;
  final String createdAt;

  InvoiceLogModel({
    required this.id,
    required this.userName,
    required this.userRole,
    required this.oldStatus,
    required this.newStatus,
    this.reason,
    required this.createdAt,
  });

  factory InvoiceLogModel.fromJson(Map<String, dynamic> json) {
    return InvoiceLogModel(
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
