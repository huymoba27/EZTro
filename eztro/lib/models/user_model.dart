class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String? phoneNumber;
  final String role;
  final int? managedHouseId;
  final bool isRenting;
  final int? roomId;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    this.managedHouseId,
    this.isRenting = false,
    this.roomId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] ?? json['id'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone'] ?? json['phone_number'],
      role: json['role'] ?? 'landlord',
      managedHouseId: json['managed_house_id'] != null ? int.tryParse(json['managed_house_id'].toString()) : null,
      isRenting: json['is_renting'] ?? false,
      roomId: json['room_id'] != null ? int.tryParse(json['room_id'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'username': username,
      'full_name': fullName,
      'phone': phoneNumber,
      'role': role,
      'managed_house_id': managedHouseId,
      'is_renting': isRenting,
      'room_id': roomId,
    };
  }
}
