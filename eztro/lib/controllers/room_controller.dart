import 'dart:io';
import 'package:flutter/material.dart';
import '../services/room_service.dart';
import '../core/utils/dialog_helper.dart';

class RoomController {
  static Future<void> submitRoom({
    required BuildContext context,
    required bool isEditMode,
    required int? roomId,
    required int? houseId,
    required String name,
    required String price,
    required String area,
    required String deposit,
    required String maxTenants,
    required List<File> images,
    List<String>? deletedImages,
    required Function(bool) setSubmitting,
    required VoidCallback onSuccess,
  }) async {
    // 1. Validation (Kiểm tra dữ liệu đầu vào)
    if (houseId == null || name.isEmpty || price.isEmpty) {
      DialogHelper.showWarning(
        context,
        "Vui lòng chọn nhà trọ, nhập tên phòng và giá thuê!",
      );
      return;
    }

    final parsedPrice = double.tryParse(price.replaceAll(',', ''));
    final parsedDeposit = deposit.isEmpty
        ? 0.0
        : double.tryParse(deposit.replaceAll(',', ''));
    final parsedArea = area.isEmpty
        ? 0.0
        : double.tryParse(area.replaceAll(',', ''));
    final parsedMaxTenants = maxTenants.isEmpty
        ? 1
        : int.tryParse(maxTenants.replaceAll(',', ''));

    if (parsedPrice == null || parsedPrice <= 0) {
      DialogHelper.showWarning(context, "Giá thuê phải là số lớn hơn 0.");
      return;
    }
    if (parsedDeposit == null || parsedDeposit < 0) {
      DialogHelper.showWarning(context, "Tiền cọc phải là số không âm.");
      return;
    }
    if (parsedArea == null || parsedArea < 0) {
      DialogHelper.showWarning(context, "Diện tích phải là số không âm.");
      return;
    }
    if (parsedMaxTenants == null || parsedMaxTenants <= 0) {
      DialogHelper.showWarning(context, "Số khách tối đa phải lớn hơn 0.");
      return;
    }

    setSubmitting(true);

    try {
      final result = isEditMode
          ? await RoomService.updateRoom(
              roomId: roomId!,
              houseId: houseId,
              roomName: name,
              price: parsedPrice,
              deposit: parsedDeposit,
              area: parsedArea,
              maxTenants: parsedMaxTenants,
              imageFiles: images,
              deletedImagePaths: deletedImages,
            )
          : await RoomService.addRoom(
              houseId: houseId,
              roomName: name,
              price: parsedPrice,
              deposit: parsedDeposit,
              area: parsedArea,
              maxTenants: parsedMaxTenants,
              imageFiles: images,
            );

      // 2. Phản hồi kết quả dựa trên status từ Server
      if (result['status'] == 'success') {
        onSuccess();
        DialogHelper.showSuccess(
          context,
          isEditMode
              ? "Đã cập nhật thông tin phòng thành công!"
              : "Đã tạo phòng mới thành công!",
          onTap: () => Navigator.pop(context, true),
        );
      } else {
        DialogHelper.showError(context, result['message'] ?? "Có lỗi xảy ra");
      }
    } catch (e) {
      DialogHelper.showError(context, "Lỗi kết nối: ${e.toString()}");
    } finally {
      setSubmitting(false);
    }
  }
}
