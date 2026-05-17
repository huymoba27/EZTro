import 'package:flutter/material.dart';

class AmenityHelper {
  static IconData getIcon(String name) {
    String n = name.toLowerCase();
    if (n.contains("wifi")) return Icons.wifi;
    if (n.contains("máy lạnh") || n.contains("điều hòa")) return Icons.ac_unit;
    if (n.contains("máy giặt")) return Icons.local_laundry_service;
    if (n.contains("tủ lạnh")) return Icons.kitchen;
    if (n.contains("giường")) return Icons.bed;
    if (n.contains("tủ")) return Icons.checkroom;
    if (n.contains("vệ sinh") || n.contains("wc")) return Icons.wc;
    if (n.contains("giờ tự do")) return Icons.access_time;
    if (n.contains("xe")) return Icons.motorcycle_outlined;
    if (n.contains("camera")) return Icons.videocam_outlined;
    if (n.contains("nước nóng")) return Icons.water_drop_outlined;
    if (n.contains("pccc") || n.contains("cứu hỏa")) return Icons.fire_extinguisher;
    if (n.contains("thang máy")) return Icons.elevator_outlined;
    if (n.contains("bếp")) return Icons.restaurant;
    if (n.contains("ban công")) return Icons.balcony;
    if (n.contains("cửa sổ")) return Icons.window;
    if (n.contains("an ninh") || n.contains("bảo vệ")) return Icons.security;
    return Icons.star_border_rounded;
  }

  static Color getColor(String name) {
    String n = name.toLowerCase();
    if (n.contains("wifi")) return Colors.blue;
    if (n.contains("máy lạnh") || n.contains("điều hòa")) return Colors.cyan;
    if (n.contains("máy giặt")) return Colors.teal;
    if (n.contains("tủ lạnh")) return Colors.blueGrey;
    if (n.contains("camera")) return Colors.red;
    if (n.contains("xe")) return Colors.orange;
    if (n.contains("nước nóng")) return Colors.lightBlue;
    if (n.contains("pccc") || n.contains("cứu hỏa")) return Colors.deepOrange;
    if (n.contains("thang máy")) return Colors.indigo;
    if (n.contains("giờ tự do")) return Colors.green;
    if (n.contains("vệ sinh") || n.contains("wc")) return Colors.brown;
    if (n.contains("giường")) return Colors.purple;
    if (n.contains("bếp")) return Colors.amber;
    if (n.contains("an ninh") || n.contains("bảo vệ")) return Colors.blueAccent;
    return const Color(0xFF1E6AF3); // Màu mặc định
  }
}
