class VehicleModel {
  final int id;
  final int tenantId;
  final String tenantName;
  final int roomId;
  final String roomName;
  final int houseId;
  final String houseName;
  final String plateNumber;
  final String vehicleType;
  final String? vehicleImage;
  final String? createdAt;

  VehicleModel({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.roomId,
    required this.roomName,
    required this.houseId,
    required this.houseName,
    required this.plateNumber,
    required this.vehicleType,
    this.vehicleImage,
    this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: int.parse(json['id'].toString()),
      tenantId: int.parse(json['tenant_id'].toString()),
      tenantName: json['tenant_name'] ?? 'N/A',
      roomId: int.parse(json['room_id'].toString()),
      roomName: json['room_name'] ?? 'N/A',
      houseId: int.parse(json['house_id'].toString()),
      houseName: json['house_name'] ?? 'N/A',
      plateNumber: json['plate_number'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      vehicleImage: json['vehicle_image'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'tenant_name': tenantName,
      'room_id': roomId,
      'room_name': roomName,
      'house_id': houseId,
      'house_name': houseName,
      'plate_number': plateNumber,
      'vehicle_type': vehicleType,
      'vehicle_image': vehicleImage,
    };
  }
}
