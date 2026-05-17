class RoomModel {
  final int id;
  final int houseId;
  final String roomName;
  final double price;
  final double deposit;
  final double area;
  final int maxTenants;
  final int currentTenants;
  final String status; // 'empty', 'available', 'full', 'fixing'
  final List<String> images;
  final String? houseName;
  final String? customerName;
  final String? customerPhone;
  final int? tenantId;

  RoomModel({
    required this.id,
    required this.houseId,
    required this.roomName,
    required this.price,
    required this.deposit,
    required this.area,
    required this.maxTenants,
    this.currentTenants = 0,
    required this.status,
    required this.images,
    this.houseName,
    this.customerName,
    this.customerPhone,
    this.tenantId,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    var imageList = json['images_list'] ?? json['images'] ?? json['first_image'];
    List<String> parsedImages = [];
    
    if (imageList is List) {
      parsedImages = imageList.map((e) => e.toString()).toList();
    } else if (imageList is String && imageList.isNotEmpty) {
      parsedImages = imageList.split(',');
    }

    return RoomModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      houseId: int.tryParse(json['house_id']?.toString() ?? '0') ?? 0,
      roomName: json['room_name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      deposit: double.tryParse(json['deposit']?.toString() ?? '0') ?? 0,
      area: double.tryParse(json['area']?.toString() ?? '0') ?? 0,
      maxTenants: int.tryParse(json['max_tenants']?.toString() ?? '0') ?? 0,
      currentTenants: int.tryParse(json['current_tenants']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'empty',
      images: parsedImages,
      houseName: json['house_name'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      tenantId: int.tryParse(json['tenant_id']?.toString() ?? ''),
    );
  }

  RoomModel copyWith({
    int? id,
    int? houseId,
    String? roomName,
    double? price,
    double? deposit,
    double? area,
    int? maxTenants,
    int? currentTenants,
    String? status,
    List<String>? images,
    String? houseName,
    String? customerName,
    String? customerPhone,
  }) {
    return RoomModel(
      id: id ?? this.id,
      houseId: houseId ?? this.houseId,
      roomName: roomName ?? this.roomName,
      price: price ?? this.price,
      deposit: deposit ?? this.deposit,
      area: area ?? this.area,
      maxTenants: maxTenants ?? this.maxTenants,
      currentTenants: currentTenants ?? this.currentTenants,
      status: status ?? this.status,
      images: images ?? this.images,
      houseName: houseName ?? this.houseName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
    );
  }

  String get statusText {
    switch (status) {
      case 'full': return "Đã đầy";
      case 'deposited': return "Đã cọc";
      case 'available': return "Còn chỗ";
      case 'fixing': return "Đang sửa";
      default: return "Phòng trống";
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'house_id': houseId,
      'room_name': roomName,
      'price': price,
      'deposit': deposit,
      'area': area,
      'max_tenants': maxTenants,
      'current_tenants': currentTenants,
      'status': status,
      'images_list': images,
      'house_name': houseName,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'tenant_id': tenantId,
    };
  }
}