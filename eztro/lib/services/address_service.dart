import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AddressService {
  static const String _baseUrl = "https://provinces.open-api.vn/api/v2";

  /// Lấy danh sách Tỉnh/Thành phố (v2 - 2025)
  static Future<List<Map<String, dynamic>>> getCities() async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/p/"));
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((e) => {'name': e['name'], 'code': e['code']}).toList();
      }
    } catch (e) {
      debugPrint("Lỗi getCities v2: $e");
    }
    return [];
  }

  /// Lấy danh sách Phường/Xã trực tiếp từ Tỉnh (Mô hình hành chính mới v2)
  static Future<List<Map<String, dynamic>>> getSubUnits(int cityCode) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/p/$cityCode?depth=2"));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List wards = data['wards'] ?? [];
        return wards.map((e) => {'name': e['name'], 'code': e['code']}).toList();
      }
    } catch (e) {
      debugPrint("Lỗi getSubUnits v2: $e");
    }
    return [];
  }

  /// Tìm kiếm code dựa trên tên (Hỗ trợ Auto-fill từ Mapbox)
  static Future<int?> findCodeByName(String name, List<Map<String, dynamic>> list) async {
    if (name.isEmpty) return null;
    final searchName = _cleanAddressName(name);
    
    for (var item in list) {
      final itemName = _cleanAddressName(item['name'].toString());
      if (itemName == searchName || itemName.contains(searchName) || searchName.contains(itemName)) {
        return item['code'] as int;
      }
    }
    return null;
  }

  static String _cleanAddressName(String name) {
    return name.toLowerCase()
        .replaceAll(RegExp(r'^(tỉnh|thành phố|quận|huyện|thị xã|xã|phường|thị trấn)\s+'), '')
        .trim();
  }
}
