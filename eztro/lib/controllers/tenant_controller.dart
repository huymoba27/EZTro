import 'package:flutter/material.dart';
import '../services/tenant_service.dart';
import '../core/utils/dialog_helper.dart';
import '../core/utils/input_validation_helper.dart';

class TenantController {
  static Future<void> addMember({
    required BuildContext context,
    required Map<String, dynamic>? selectedRoom,
    required TextEditingController nameController,
    required TextEditingController phoneController,
    required TextEditingController emailController,
    required TextEditingController birthdayController,
    required TextEditingController idCardController,
    required TextEditingController idCardDateController,
    required TextEditingController idCardPlaceController,
    required TextEditingController addressController,
    required String selectedGender,
    required dynamic frontImg,
    required dynamic backImg,
    required Function(bool) setSubmitting,
  }) async {
    if (selectedRoom == null ||
        nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      DialogHelper.showWarning(
        context,
        "Vui lòng chọn phòng và nhập đầy đủ tên, số điện thoại!",
      );
      return;
    }
    final phoneError = InputValidationHelper.phoneError(phoneController.text);
    if (phoneError != null) {
      DialogHelper.showWarning(context, phoneError);
      return;
    }

    setSubmitting(true);
    try {
      final res = await TenantService.addMember(
        roomId: int.parse(selectedRoom['id'].toString()),
        tenantName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        gender: selectedGender,
        birthday: birthdayController.text,
        email: emailController.text.trim(),
        idCard: idCardController.text.trim(),
        idCardDate: idCardDateController.text,
        idCardPlace: idCardPlaceController.text,
        address: addressController.text,
        imageFront: frontImg,
        imageBack: backImg,
      );

      if (res['status'] == 'success') {
        DialogHelper.showSuccess(
          context,
          "Thêm thành viên thành công!",
          onTap: () => Navigator.pop(context, true),
        );
      } else {
        DialogHelper.showError(
          context,
          res['message'] ?? "Lỗi khi thêm thành viên!",
        );
      }
    } catch (e) {
      DialogHelper.showError(context, "Lỗi kết nối: ${e.toString()}");
    } finally {
      setSubmitting(false);
    }
  }
}
