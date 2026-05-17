import 'package:flutter/material.dart';
import '../services/service_manage_service.dart';
import '../core/utils/dialog_helper.dart';

class ServiceController {
  static Future<void> submitService({
    required BuildContext context,
    required bool isEditMode,
    int? serviceId,
    required String name,
    required String priceText,
    required String unit,
    required String chargeType,
    required String serviceType,
    required List<int> houseIds,
    required Function(bool) setLoading,
  }) async {
    // 1. Validation
    if (name.isEmpty ||
        priceText.isEmpty ||
        (!isEditMode && houseIds.isEmpty)) {
      DialogHelper.showWarning(context, "Vui lòng nhập đầy đủ thông tin!");
      return;
    }

    final price = double.tryParse(priceText.replaceAll(',', ''));
    if (price == null || price <= 0) {
      DialogHelper.showWarning(
        context,
        "Đơn giá dịch vụ phải là số lớn hơn 0.",
      );
      return;
    }

    setLoading(true);
    try {
      var res = isEditMode
          ? await ServiceManageService.updateService(
              id: serviceId!,
              name: name,
              price: price,
              unit: unit,
              charge_type: chargeType,
              service_type: serviceType,
            )
          : await ServiceManageService.addService(
              name: name,
              price: price,
              unit: unit,
              charge_type: chargeType,
              service_type: serviceType,
              houseIds: houseIds,
            );

      if (res['status'] == 'success') {
        DialogHelper.showSuccess(
          context,
          isEditMode
              ? "Đã cập nhật dịch vụ thành công!"
              : "Đã tạo dịch vụ thành công!",
          onTap: () => Navigator.pop(context, true),
        );
      } else {
        DialogHelper.showError(context, res['message']);
      }
    } catch (e) {
      DialogHelper.showError(context, "Lỗi: ${e.toString()}");
    } finally {
      setLoading(false);
    }
  }
}
