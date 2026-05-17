class ServiceModel {
  final int id;
  final String serviceName;
  final double price;
  final String unit;
  final String? description;
  final int? houseId;
  final int? totalHouses; // Chỉ dùng cho mode xem tất cả

  ServiceModel({
    required this.id,
    required this.serviceName,
    required this.price,
    required this.unit,
    this.description,
    this.houseId,
    this.totalHouses,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: int.tryParse(json['service_id']?.toString() ?? json['id']?.toString() ?? "0") ?? 0,
      serviceName: json['service_name']?.toString() ?? json['name']?.toString() ?? "N/A",
      price: double.tryParse(json['service_price']?.toString() ?? json['price']?.toString() ?? "0") ?? 0,
      unit: json['unit']?.toString() ?? "đơn vị",
      description: json['description']?.toString(),
      houseId: int.tryParse(json['house_id']?.toString() ?? "0"),
      totalHouses: int.tryParse(json['total_houses']?.toString() ?? "0"),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_name': serviceName,
      'price': price,
      'unit': unit,
      'description': description,
      'house_id': houseId,
      'total_houses': totalHouses,
    };
  }
}
