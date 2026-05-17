import 'service_model.dart';

class ContractModel {
  final int id;
  final int? contractId;
  final int roomId;
  final String roomName;
  final int? houseId;
  final String? houseName;
  final int? tenantId;
  final String? tenantName;
  final String? tenantPhone;
  final String? email;
  final String? birthday;
  final String? gender;
  final String? idCard;
  final String? idCardDate;
  final String? idCardPlace;
  final String? address;
  final String? addressDetail;
  final String? ward;
  final String? city;
  final String startDate;
  final String endDate;
  final String status;
  final double rentPrice;
  final double depositAmount;
  final int paymentDay;
  final int startElectric;
  final int startWater;
  final String? ownerName;
  final String? ownerPhone;
  final List<ServiceModel>? services;
  final List<ContractLogModel>? logs;
  final DateTime? createdAt;

  ContractModel({
    required this.id,
    this.contractId,
    required this.roomId,
    required this.roomName,
    this.houseId,
    this.houseName,
    this.tenantId,
    this.tenantName,
    this.tenantPhone,
    this.email,
    this.birthday,
    this.gender,
    this.idCard,
    this.idCardDate,
    this.idCardPlace,
    this.address,
    this.addressDetail,
    this.ward,
    this.city,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.rentPrice,
    required this.depositAmount,
    required this.paymentDay,
    required this.startElectric,
    required this.startWater,
    this.ownerName,
    this.ownerPhone,
    this.services,
    this.logs,
    this.createdAt,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: int.parse(json['id']?.toString() ?? json['contract_id']?.toString() ?? '0'),
      contractId: int.tryParse(json['contract_id']?.toString() ?? ''),
      roomId: int.parse(json['room_id']?.toString() ?? '0'),
      roomName: json['room_name']?.toString() ?? 'N/A',
      houseId: int.tryParse(json['house_id']?.toString() ?? ''),
      houseName: json['house_name']?.toString(),
      tenantId: int.tryParse(json['tenant_id']?.toString() ?? ''),
      tenantName: _parseString(json['tenant_name'] ?? json['customer_name']),
      tenantPhone: _parseString(json['tenant_phone'] ?? json['customer_phone']),
      ownerName: _parseString(json['owner_name']),
      ownerPhone: _parseString(json['owner_phone']),
      email: json['email']?.toString(),
      birthday: json['birthday']?.toString(),
      gender: json['gender']?.toString(),
      idCard: json['id_card']?.toString(),
      idCardDate: json['id_card_date']?.toString(),
      idCardPlace: json['id_card_place']?.toString(),
      address: json['address']?.toString(),
      addressDetail: json['address_detail']?.toString(),
      ward: json['ward']?.toString(),
      city: json['city']?.toString(),
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? 'Vô hạn',
      status: json['status']?.toString() ?? 'inactive',
      rentPrice: double.tryParse(json['rent_price']?.toString() ?? json['price']?.toString() ?? '0') ?? 0,
      depositAmount: double.tryParse(json['deposit_amount']?.toString() ?? json['deposit']?.toString() ?? '0') ?? 0,
      paymentDay: int.tryParse(json['payment_day']?.toString() ?? '1') ?? 1,
      startElectric: int.tryParse(json['start_electric_index']?.toString() ?? json['start_electric']?.toString() ?? '0') ?? 0,
      startWater: int.tryParse(json['start_water_index']?.toString() ?? json['start_water']?.toString() ?? '0') ?? 0,
      services: json['services'] != null 
          ? (json['services'] as List).map((s) => ServiceModel.fromJson(s)).toList() 
          : null,
      logs: json['logs'] != null 
          ? (json['logs'] as List).map((l) => ContractLogModel.fromJson(l)).toList() 
          : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract_id': contractId,
      'room_id': roomId,
      'room_name': roomName,
      'house_id': houseId,
      'house_name': houseName,
      'tenant_id': tenantId,
      'tenant_name': tenantName,
      'tenant_phone': tenantPhone,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'email': email,
      'birthday': birthday,
      'gender': gender,
      'id_card': idCard,
      'id_card_date': idCardDate,
      'id_card_place': idCardPlace,
      'address': address,
      'address_detail': addressDetail,
      'ward': ward,
      'city': city,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
      'rent_price': rentPrice,
      'deposit_amount': depositAmount,
      'payment_day': paymentDay,
      'start_electric': startElectric,
      'start_water': startWater,
      'services': services?.map((s) => s.toJson()).toList(),
      'logs': logs?.map((l) => l.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    String str = value.toString();
    if (str.isEmpty || str.toLowerCase() == "null") return null;
    return str;
  }
}

class ContractLogModel {
  final int id;
  final String userName;
  final String userRole;
  final String action;
  final String? oldStatus;
  final String? newStatus;
  final String? reason;
  final double refundAmount;
  final String createdAt;

  ContractLogModel({
    required this.id,
    required this.userName,
    required this.userRole,
    required this.action,
    this.oldStatus,
    this.newStatus,
    this.reason,
    required this.refundAmount,
    required this.createdAt,
  });

  factory ContractLogModel.fromJson(Map<String, dynamic> json) {
    return ContractLogModel(
      id: int.parse(json['id']?.toString() ?? '0'),
      userName: json['user_name']?.toString() ?? 'N/A',
      userRole: json['user_role']?.toString() ?? 'landlord',
      action: json['action']?.toString() ?? 'update',
      oldStatus: json['old_status']?.toString(),
      newStatus: json['new_status']?.toString(),
      reason: json['reason']?.toString(),
      refundAmount: double.tryParse(json['refund_amount']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'user_role': userRole,
      'action': action,
      'old_status': oldStatus,
      'new_status': newStatus,
      'reason': reason,
      'refund_amount': refundAmount,
      'created_at': createdAt,
    };
  }
}
