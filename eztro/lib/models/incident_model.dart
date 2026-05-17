import 'dart:convert';

class IncidentModel {
  final int? id;
  final int tenantId;
  final String? tenantName;
  final int roomId;
  final String roomName;
  final String? houseName;
  final String title;
  final String description;
  final List<String> images;
  final String status;
  final double? repairCost;
  final int? expenseId;
  final DateTime createdAt;

  IncidentModel({
    this.id,
    required this.tenantId,
    this.tenantName,
    required this.roomId,
    required this.roomName,
    this.houseName,
    required this.title,
    required this.description,
    required this.images,
    required this.status,
    this.repairCost,
    this.expenseId,
    required this.createdAt,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    List<String> imageList = [];
    if (json['images'] != null && json['images'].toString().isNotEmpty) {
      final dynamic rawImages = json['images'];
      if (rawImages is List) {
        imageList = rawImages.map((e) => e.toString()).toList();
      } else if (rawImages is String) {
        if (rawImages.startsWith('[')) {
          try {
            imageList = List<String>.from(jsonDecode(rawImages));
          } catch (e) {
            imageList = rawImages.split(',').where((s) => s.isNotEmpty).toList();
          }
        } else {
          imageList = rawImages.split(',').where((s) => s.isNotEmpty).toList();
        }
      }
    }

    return IncidentModel(
      id: int.tryParse(json['id'].toString()),
      tenantId: int.parse(json['tenant_id'].toString()),
      tenantName: json['tenant_name'],
      roomId: int.parse(json['room_id'].toString()),
      roomName: json['room_name'] ?? 'N/A',
      houseName: json['house_name'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      images: imageList,
      status: json['status'] ?? 'pending',
      repairCost: json['repair_cost'] != null ? double.tryParse(json['repair_cost'].toString()) : null,
      expenseId: json['expense_id'] != null ? int.tryParse(json['expense_id'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'tenant_name': tenantName,
      'room_id': roomId,
      'room_name': roomName,
      'house_name': houseName,
      'title': title,
      'description': description,
      'images': images,
      'status': status,
      'repair_cost': repairCost,
      'expense_id': expenseId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
