import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/house_service.dart';
import '../models/house_model.dart';
import '../core/utils/dialog_helper.dart';

class HouseController {
  static Future<void> submitHouse({
    required BuildContext context,
    required int userId,
    required bool isEditMode,
    required HouseModel? existingHouse,
    required String name,
    required String city,
    required String ward,
    required String addressDetail,
    required List<int> selectedAmenities,
    XFile? imageFile,
    required Function(bool) setLoading,
    double? latitude,
    double? longitude,
    double? totalArea,
    int? floors,
    String? ownerName,
    String? ownerPhone,
  }) async {
    // 1. Kiểm tra điều kiện (Validation)
    if (name.isEmpty || ward.contains("Chọn")) {
      DialogHelper.showWarning(context, "Vui lòng nhập đủ tên nhà và địa chỉ!");
      return;
    }

    setLoading(true);
    
    try {
      Map<String, dynamic> result;
      
      if (isEditMode) {
        result = await HouseService.updateHouse(
          houseId: existingHouse!.id, 
          name: name, 
          city: city, 
          ward: ward, 
          addressDetail: addressDetail,
          selectedAmenities: selectedAmenities, 
          imageFile: imageFile != null ? File(imageFile.path) : null,
          latitude: latitude,
          longitude: longitude,
          totalArea: totalArea,
          floors: floors,
          ownerName: ownerName,
          ownerPhone: ownerPhone,
        );
      } else {
        result = await HouseService.addHouse(
          userId: userId,
          name: name, 
          city: city, 
          ward: ward, 
          addressDetail: addressDetail,
          selectedAmenities: selectedAmenities, 
          imageFile: imageFile != null ? File(imageFile.path) : null,
          latitude: latitude,
          longitude: longitude,
          totalArea: totalArea,
          floors: floors,
          ownerName: ownerName,
          ownerPhone: ownerPhone,
        );
      }

      // 2. Xử lý phản hồi từ Server
      if (result['status'] == 'success') {
        DialogHelper.showSuccess(
          context, 
          isEditMode ? "Đã cập nhật thông tin nhà trọ thành công!" : "Đã tạo nhà trọ mới thành công!", 
          onTap: () => Navigator.pop(context, true)
        );
      } else {
        DialogHelper.showError(context, result['message']);
      }
    } catch (e) {
      DialogHelper.showError(context, "Lỗi kết nối đến máy chủ!");
    } finally {
      setLoading(false);
    }
  }
}