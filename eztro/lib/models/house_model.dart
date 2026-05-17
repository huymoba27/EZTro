class HouseModel {
  final int id;
  final String houseName;
  final String image;
  final String status;
  final String city;
  final String ward;
  final String? addressDetail;
  final List<Amenity>? amenities;
  final int totalRooms;
  final int totalEmptyRooms;
  final int totalTenants;
  final double? latitude;
  final double? longitude;
  final double? totalArea;
  final int? floors;
  final String? ownerName;
  final String? ownerPhone;
  final String? managerName;
  final String? managerPhone;

  List<int> get amenityIds => amenities?.map((a) => a.id).toList() ?? [];

  HouseModel({
    required this.id,
    required this.houseName,
    required this.image,
    required this.status,
    required this.city,
    required this.ward,
    this.addressDetail,
    this.amenities,
    this.totalRooms = 0,
    this.totalEmptyRooms = 0,
    this.totalTenants = 0,
    this.latitude,
    this.longitude,
    this.totalArea,
    this.floors,
    this.ownerName,
    this.ownerPhone,
    this.managerName,
    this.managerPhone,
  });

  factory HouseModel.fromJson(Map<String, dynamic> json) {
    var amenityList = json['amenities'] as List?;
    List<Amenity> parsedAmenities = [];
    if (amenityList != null) {
      parsedAmenities = amenityList.map((i) => Amenity.fromJson(i)).toList();
    }

    return HouseModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      houseName: json['house_name'] ?? '',
      image: json['image'] ?? "",
      status: json['status'] ?? "active",
      city: json['city'] ?? '',
      ward: json['ward'] ?? '',
      addressDetail: json['address_detail'],
      totalRooms: int.tryParse(json['total_rooms']?.toString() ?? '0') ?? 0,
      totalEmptyRooms: int.tryParse(json['total_empty_rooms']?.toString() ?? '0') ?? 0,
      totalTenants: int.tryParse(json['total_tenants']?.toString() ?? '0') ?? 0,
      amenities: parsedAmenities,
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      totalArea: double.tryParse(json['total_area']?.toString() ?? ''),
      floors: int.tryParse(json['floors']?.toString() ?? ''),
      ownerName: json['owner_name'] ?? json['full_name'] ?? json['landlord_name'] ?? json['house_owner_name'],
      ownerPhone: json['owner_phone'] ?? json['phone'] ?? json['username'] ?? json['landlord_phone'],
      managerName: json['manager_name'],
      managerPhone: json['manager_phone'],
    );
  }

  HouseModel copyWith({
    int? id,
    String? houseName,
    String? image,
    String? status,
    String? city,
    String? ward,
    String? addressDetail,
    List<Amenity>? amenities,
    int? totalRooms,
    int? totalTenants,
    double? latitude,
    double? longitude,
    double? totalArea,
    int? floors,
  }) {
    return HouseModel(
      id: id ?? this.id,
      houseName: houseName ?? this.houseName,
      image: image ?? this.image,
      status: status ?? this.status,
      city: city ?? this.city,
      ward: ward ?? this.ward,
      addressDetail: addressDetail ?? this.addressDetail,
      amenities: amenities ?? this.amenities,
      totalRooms: totalRooms ?? this.totalRooms,
      totalTenants: totalTenants ?? this.totalTenants,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      totalArea: totalArea ?? this.totalArea,
      floors: floors ?? this.floors,
    );
  }

  String get fullAddress {
    List<String> parts = [];
    if (addressDetail != null && addressDetail!.isNotEmpty) parts.add(addressDetail!);
    if (ward.isNotEmpty) parts.add(ward);
    if (city.isNotEmpty) parts.add(city);
    return parts.join(", ");
  }

  static String formatAddress({
    String? addressDetail,
    required String ward,
    required String city,
  }) {
    List<String> parts = [];
    if (addressDetail != null && addressDetail.isNotEmpty) parts.add(addressDetail);
    if (ward.isNotEmpty) parts.add(ward);
    if (city.isNotEmpty) parts.add(city);
    return parts.join(", ");
  }
}

class Amenity {
  final int id;
  final String name;

  Amenity({required this.id, required this.name});

  factory Amenity.fromJson(Map<String, dynamic> json) {
    return Amenity(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
    );
  }
}