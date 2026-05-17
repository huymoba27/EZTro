class TenantModel {
  final int id;
  final String tenantName;
  final String? phone;
  final String? gender;
  final String? birthday;
  final String? email;
  final String? idCard;
  final String? idCardDate;
  final String? idCardPlace;
  final String? address;
  final String? cccdFront;
  final String? cccdBack;
  final String? houseName;
  final String? roomName;
  final int? houseId;
  final int isRepresentative;
  final String? fullAddress;
  final String status;
  final List<TenantLogModel> logs;


  TenantModel({
    required this.id,
    required this.tenantName,
    this.phone,
    this.gender,
    this.birthday,
    this.email,
    this.idCard,
    this.idCardDate,
    this.idCardPlace,
    this.address,
    this.cccdFront,
    this.cccdBack,
    this.houseName,
    this.roomName,
    this.houseId,
    required this.isRepresentative,
    this.fullAddress,
    String? status,
    this.logs = const [],
  }) : status = status ?? 'active';

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tenantName: json['tenant_name'] ?? json['fullname'] ?? 'Không tên',
      phone: json['phone']?.toString(),
      gender: json['gender']?.toString(),
      birthday: json['birthday']?.toString(),
      email: json['email']?.toString(),
      idCard: json['id_card']?.toString(),
      idCardDate: json['id_card_date']?.toString(),
      idCardPlace: json['id_card_place']?.toString(),
      address: json['address']?.toString(),
      cccdFront: json['cccd_front']?.toString(),
      cccdBack: json['cccd_back']?.toString(),
      houseName: json['house_name']?.toString(),
      roomName: json['room_name']?.toString(),
      houseId: int.tryParse(json['house_id']?.toString() ?? ''),
      isRepresentative: int.tryParse(json['is_representative']?.toString() ?? '0') ?? 0,
      fullAddress: json['full_address']?.toString(),
      status: (json['status'] ?? 'active').toString(),
      logs: json['logs'] != null
          ? (json['logs'] as List)
              .map((i) => TenantLogModel.fromJson(i))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_name': tenantName,
      'phone': phone,
      'gender': gender,
      'birthday': birthday,
      'email': email,
      'id_card': idCard,
      'id_card_date': idCardDate,
      'id_card_place': idCardPlace,
      'address': address,
      'cccd_front': cccdFront,
      'cccd_back': cccdBack,
      'house_name': houseName,
      'room_name': roomName,
      'house_id': houseId,
      'is_representative': isRepresentative,
      'full_address': fullAddress,
      'status': status,
      'logs': logs.map((e) => e.toJson()).toList(),
    };
  }

  bool get isLead => isRepresentative == 1;
}

class TenantLogModel {
  final int id;
  final String action;
  final String oldStatus;
  final String newStatus;
  final String? reason;
  final String userName;
  final String userRole;
  final String createdAt;

  TenantLogModel({
    required this.id,
    required this.action,
    required this.oldStatus,
    required this.newStatus,
    this.reason,
    required this.userName,
    required this.userRole,
    required this.createdAt,
  });

  factory TenantLogModel.fromJson(Map<String, dynamic> json) {
    return TenantLogModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      action: json['action']?.toString() ?? '',
      oldStatus: json['old_status']?.toString() ?? '',
      newStatus: json['new_status']?.toString() ?? '',
      reason: json['reason']?.toString(),
      userName: json['user_name']?.toString() ?? 'Hệ thống',
      userRole: json['user_role']?.toString() ?? 'system',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'old_status': oldStatus,
      'new_status': newStatus,
      'reason': reason,
      'user_name': userName,
      'user_role': userRole,
      'created_at': createdAt,
    };
  }
}