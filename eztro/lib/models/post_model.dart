class PostModel {
  final int? id;
  final int roomId;
  final String title;
  final String description;
  final String? images;
  final String? priceDisplay;
  final String status;
  final String createdAt;
  
  // Joined fields
  final String? roomName;
  final String? houseName;
  final String? area;
  final String? originalPrice;
  final String? addressDetail;
  final String? city;
  final String? ward;
  final double? deposit;
  final int? maxTenants;

  // New Detailed fields
  final List<String>? allImages;
  final String? ownerName;
  final int? ownerId;
  final String? ownerPhone;
  final String? managerName;
  final int? managerId;
  final String? managerPhone;
  final List<dynamic>? services;
  final List<String>? amenities;
  final double? latitude;
  final double? longitude;
  final String? houseRules;
  final int? houseId;
  final bool isFavorited;

  final double? electricPrice;
  final double? waterPrice;

  PostModel({
    this.id,
    required this.roomId,
    required this.title,
    required this.description,
    this.images,
    this.priceDisplay,
    this.status = 'active',
    this.createdAt = '',
    this.roomName,
    this.houseName,
    this.area,
    this.originalPrice,
    this.addressDetail,
    this.city,
    this.ward,
    this.allImages,
    this.ownerName,
    this.ownerId,
    this.ownerPhone,
    this.managerName,
    this.managerId,
    this.managerPhone,
    this.services,
    this.amenities,
    this.latitude,
    this.longitude,
    this.houseRules,
    this.houseId,
    this.isFavorited = false,
    this.deposit,
    this.maxTenants,
    this.electricPrice,
    this.waterPrice,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: int.tryParse(json['id'].toString()),
      roomId: int.parse(json['room_id'].toString()),
      title: json['title'] ?? '',
      description: (json['description'] ?? '').toString().replaceAll('\\n', '\n'),
      images: json['images'],
      priceDisplay: json['price_display'],
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] ?? '',
      roomName: json['room_name'],
      houseName: json['house_name'],
      area: json['area']?.toString(),
      originalPrice: json['original_price']?.toString(),
      addressDetail: json['address_detail'],
      city: json['city'],
      ward: json['ward'],
      
      // Detailed fields
      allImages: json['all_images'] != null ? List<String>.from(json['all_images']) : [],
      ownerName: json['owner_name'],
      ownerId: int.tryParse(json['owner_id']?.toString() ?? ''),
      ownerPhone: json['owner_phone'],
      managerName: json['manager_name'],
      managerId: int.tryParse(json['manager_id']?.toString() ?? ''),
      managerPhone: json['manager_phone'],
      services: json['services'],
      amenities: json['house_amenities'] != null 
          ? (json['house_amenities'] as String).split(', ').where((s) => s.isNotEmpty).toList()
          : (json['amenities'] != null ? List<String>.from(json['amenities']) : []),
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      houseRules: json['house_rules'] ?? json['house_notes'],
      houseId: int.tryParse(json['house_id']?.toString() ?? ''),
      isFavorited: (json['is_favorited'] ?? 0).toString() == "1",
      deposit: double.tryParse(json['deposit']?.toString() ?? ''),
      maxTenants: int.tryParse(json['max_tenants']?.toString() ?? ''),
      electricPrice: double.tryParse(json['electric_price']?.toString() ?? ''),
      waterPrice: double.tryParse(json['water_price']?.toString() ?? ''),
    );
  }

  Map<String, String> toMap() {
    return {
      'room_id': roomId.toString(),
      'title': title,
      'description': description,
      'price_display': priceDisplay ?? '',
      'images': images ?? '',
      'house_rules': houseRules ?? '',
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'images': allImages,
      'price_display': priceDisplay ?? originalPrice,
      'house_name': houseName,
    };
  }

  // Helper for contact
  String get contactName => (managerName != null && managerName!.isNotEmpty) ? managerName! : (ownerName ?? 'Chủ trọ');
  String get contactPhone => (managerPhone != null && managerPhone!.isNotEmpty) ? managerPhone! : (ownerPhone ?? '');
  int? get contactUserId => (managerId != null && managerId != 0) ? managerId : ownerId;
}
